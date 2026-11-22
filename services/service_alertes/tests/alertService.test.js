jest.mock('nodemailer', () => ({
  createTransport: jest.fn(() => ({ sendMail: jest.fn() })),
}));
jest.mock('uuid', () => ({ v4: () => 'abcdef12-3456-7890-abcd-ef1234567890' }));
jest.mock('sequelize', () => ({ Op: {} }));
jest.mock('../src/models/Alert', () => ({ create: jest.fn() }));
jest.mock('../src/models/AlertRecipient', () => ({ findAll: jest.fn() }));

const nodemailer = require('nodemailer');
const Alert = require('../src/models/Alert');
const AlertRecipient = require('../src/models/AlertRecipient');
const alertService = require('../src/services/alertService');

const fakeAlert = () => ({
  toJSON: () => ({}),
  update: jest.fn().mockResolvedValue(undefined),
});

describe('AlertService.createAlert', () => {
  const originalEnv = process.env;
  let logSpy;
  let errorSpy;

  beforeEach(() => {
    jest.clearAllMocks();
    process.env = { ...originalEnv };
    logSpy = jest.spyOn(console, 'log').mockImplementation(() => {});
    errorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
  });

  afterEach(() => {
    process.env = originalEnv;
    logSpy.mockRestore();
    errorSpy.mockRestore();
  });


  it('fills alert_id, default severity and alert_data', async () => {
    process.env.EMAIL_ENABLED = 'false';
    const created = fakeAlert();
    Alert.create.mockResolvedValue(created);
    AlertRecipient.findAll.mockResolvedValue([]);

    const result = await alertService.createAlert({
      type: 'ph_high',
      message: 'pH above WHO limit',
      score_qualite: 42,
    });

    const saved = Alert.create.mock.calls[0][0];
    expect(saved.alert_id).toMatch(/^ALERT_\d+_abcdef12$/);
    expect(saved.severity).toBe('medium');
    expect(saved.alert_data).toEqual({
      type: 'ph_high',
      message: 'pH above WHO limit',
      score_qualite: 42,
    });
    expect(result).toBe(created);
  });

  it('keeps an explicit severity', async () => {
    process.env.EMAIL_ENABLED = 'false';
    Alert.create.mockResolvedValue(fakeAlert());
    AlertRecipient.findAll.mockResolvedValue([]);

    await alertService.createAlert({ severity: 'critical', type: 'turbidity' });

    expect(Alert.create.mock.calls[0][0].severity).toBe('critical');
  });

  it('leaves the alert pending when e-mail is disabled', async () => {
    process.env.EMAIL_ENABLED = 'false';
    const created = fakeAlert();
    Alert.create.mockResolvedValue(created);
    AlertRecipient.findAll.mockResolvedValue([{ email: 'a@example.com' }]);
    const send = jest.spyOn(alertService, 'sendEmailNotification');

    await alertService.createAlert({ type: 'ph_low' });

    expect(send).not.toHaveBeenCalled();
    expect(created.update).not.toHaveBeenCalled();
    send.mockRestore();
  });

  it('marks the alert sent when every e-mail is delivered', async () => {
    process.env.EMAIL_ENABLED = 'true';
    const created = fakeAlert();
    Alert.create.mockResolvedValue(created);
    AlertRecipient.findAll.mockResolvedValue([{ email: 'a@example.com' }, { email: 'b@example.com' }]);
    const send = jest.spyOn(alertService, 'sendEmailNotification').mockResolvedValue(undefined);

    await alertService.createAlert({ type: 'ph_low' });

    expect(send).toHaveBeenCalledTimes(2);
    expect(created.update).toHaveBeenCalledWith({ status: 'sent' });
    send.mockRestore();
  });

  it('marks the alert failed when no recipient is active', async () => {
    process.env.EMAIL_ENABLED = 'true';
    const created = fakeAlert();
    Alert.create.mockResolvedValue(created);
    AlertRecipient.findAll.mockResolvedValue([]);

    await alertService.createAlert({ type: 'ph_low' });

    expect(created.update).toHaveBeenCalledWith({ status: 'failed' });
  });

  it('marks the alert failed when every delivery fails', async () => {
    process.env.EMAIL_ENABLED = 'true';
    const created = fakeAlert();
    Alert.create.mockResolvedValue(created);
    AlertRecipient.findAll.mockResolvedValue([{ email: 'a@example.com' }]);
    const send = jest
      .spyOn(alertService, 'sendEmailNotification')
      .mockRejectedValue(new Error('SMTP down'));

    await alertService.createAlert({ type: 'ph_low' });

    expect(created.update).toHaveBeenCalledWith({ status: 'failed' });
    send.mockRestore();
  });

  it('propagates database errors', async () => {
    Alert.create.mockRejectedValue(new Error('db unavailable'));

    await expect(alertService.createAlert({ type: 'ph_low' })).rejects.toThrow('db unavailable');
  });
});
