import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spidertask/stockController.dart';


class StockPage extends StatelessWidget {
  final controller = Get.put(StockController());

  StockPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📈 Stock Tracker')),
      body: Column(
        children: [
          Obx(() => Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: _statusColor(controller.connectionStatus.value),
            child: Text(
              controller.connectionStatus.value.name.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1.2,
              ),
            ),
          )),

          Expanded(
            child: Obx(() {
              final stockList = controller.stocks.values.toList();

              if (stockList.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              return ListView.separated(
                itemCount: stockList.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final stock = stockList[index];
                  final priceChange = (stock.previousPrice != null)
                      ? stock.price - stock.previousPrice!
                      : 0.0;
                  final isUp = priceChange > 0;
                  final isDown = priceChange < 0;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Row(
                      children: [
                        Text(
                          stock.ticker,
                          style: const TextStyle(fontSize: 18),
                        ),
                        if (stock.isAnomalous) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.warning, color: Colors.amber, size: 18),
                        ]
                      ],
                    ),
                    trailing: TweenAnimationBuilder<Color?>(
                      duration: const Duration(milliseconds: 600),
                      tween: ColorTween(
                        begin: isUp
                            ? Colors.green.withOpacity(0.5)
                            : isDown
                            ? Colors.red.withOpacity(0.5)
                            : Colors.grey.withOpacity(0.1),
                        end: Colors.transparent,
                      ),
                      builder: (_, color, child) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: child,
                      ),
                      child: Text(
                        '\$${stock.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: stock.isAnomalous
                              ? Colors.amber.shade700
                              : isUp
                              ? Colors.green
                              : isDown
                              ? Colors.red
                              : Colors.black,
                        ),
                      ),
                    ),
                  );

                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Color _statusColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return Colors.green;
      case ConnectionStatus.connecting:
      case ConnectionStatus.reconnecting:
        return Colors.orange;
      case ConnectionStatus.disconnected:
        return Colors.red;
    }
  }
}
