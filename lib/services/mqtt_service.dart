/// Сервис подключения к MQTT-брокеру.
///
/// Заглушка: реализация появится позже, когда сервер начнёт
/// публиковать данные устройств в топики.
class MqttService {
  MqttService._();
  static final MqttService instance = MqttService._();

  bool _connected = false;
  bool get isConnected => _connected;

  Future<void> connect() async {
    // TODO: подключение к брокеру и подписка на топики устройств.
  }

  Future<void> disconnect() async {
    _connected = false;
  }
}
