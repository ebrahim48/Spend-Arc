import 'package:equatable/equatable.dart';

class ChartPoint extends Equatable {
  final DateTime date;
  final double income;
  final double expense;

  const ChartPoint({
    required this.date,
    required this.income,
    required this.expense,
  });

  double get net => income - expense;

  @override
  List<Object> get props => [date, income, expense];
}

class SpendingChartData extends Equatable {
  final List<ChartPoint> points;
  final double maxValue;
  final double minValue;

  const SpendingChartData({
    required this.points,
    required this.maxValue,
    required this.minValue,
  });

  @override
  List<Object> get props => [points, maxValue, minValue];
}
