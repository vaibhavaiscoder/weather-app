class Stock {
  final String ticker;
  final double price;
  final double? previousPrice;
  final bool isAnomalous;

  Stock({
    required this.ticker,
    required this.price,
    this.previousPrice,
    this.isAnomalous = false,
  });

  Stock copyWith({
    double? price,
    double? previousPrice,
    bool? isAnomalous,
  }) {
    return Stock(
      ticker: ticker,
      price: price ?? this.price,
      previousPrice: previousPrice ?? this.previousPrice,
      isAnomalous: isAnomalous ?? this.isAnomalous,
    );
  }
}
