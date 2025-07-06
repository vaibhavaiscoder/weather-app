import 'dart:convert';

import 'package:get/get.dart';
import 'package:spidertask/stockModel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:math';

enum ConnectionStatus { connecting, connected, reconnecting, disconnected }

class StockController extends GetxController {
  final RxMap<String, Stock> stocks = <String, Stock>{}.obs;
  final Rx<ConnectionStatus> connectionStatus = ConnectionStatus.connecting.obs;
  WebSocketChannel? _channel;
  int reconnectDelay = 2; // seconds
  final int maxReconnectDelay = 30;

  @override
  void onInit() {
    super.onInit();
    connect();
  }

  void connect() {
    connectionStatus.value = ConnectionStatus.connecting;
    try {
      _channel = WebSocketChannel.connect(Uri.parse('ws://192.168.31.49:8080/ws'));
      connectionStatus.value = ConnectionStatus.connected;
      reconnectDelay = 2; // reset

      _channel!.stream.listen(
            (data) {
          try {
            final decoded = jsonDecode(data);
            if (decoded is List) {
              for (var entry in decoded) {
                final ticker = entry['ticker'];
                final newPrice = double.tryParse(entry['price']) ?? 0;
                final oldStock = stocks[ticker];

                final isAnomaly = oldStock != null &&
                    oldStock.price > 0 &&
                    ((oldStock.price - newPrice) / oldStock.price) > 0.8;

                if (isAnomaly) {
                  stocks[ticker] = oldStock.copyWith(isAnomalous: true);
                } else {
                  stocks[ticker] = Stock(
                    ticker: ticker,
                    price: newPrice,
                    previousPrice: oldStock?.price,
                    isAnomalous: false,
                  );
                }
              }
            }
          } catch (e) {
            print('Malformed JSON: $e');
          }
        },
        onDone: _handleDisconnect,
        onError: (error) {
          print('WebSocket error: $error');
          _handleDisconnect();
        },
      );
    } catch (e) {
      print('Connection error: $e');
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    connectionStatus.value = ConnectionStatus.disconnected;
    reconnect();
  }

  void reconnect() {
    connectionStatus.value = ConnectionStatus.reconnecting;
    Future.delayed(Duration(seconds: reconnectDelay), connect);
    reconnectDelay = min(reconnectDelay * 2, maxReconnectDelay);
  }

  @override
  void onClose() {
    _channel?.sink.close(status.normalClosure);
    super.onClose();
  }
}

