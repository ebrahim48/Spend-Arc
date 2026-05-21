import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/budget_summary.dart';
import '../../../domain/usecases/budget/get_budget_summary.dart';

part 'budget_event.dart';
part 'budget_state.dart';

class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  final GetBudgetSummary getBudgetSummary;
  DateTime _currentMonth = DateTime.now();

  BudgetBloc({required this.getBudgetSummary}) : super(BudgetInitial()) {
    on<LoadBudgetSummary>(_onLoad);
    on<RefreshBudget>(_onRefresh);
  }

  Future<void> _onLoad(
    LoadBudgetSummary event,
    Emitter<BudgetState> emit,
  ) async {
    _currentMonth = event.month;
    emit(BudgetLoading());
    final result =
        await getBudgetSummary(GetBudgetSummaryParams(month: event.month));
    result.fold(
      (failure) => emit(BudgetError(failure.message)),
      (summary) => emit(BudgetLoaded(summary: summary, month: event.month)),
    );
  }

  Future<void> _onRefresh(
    RefreshBudget event,
    Emitter<BudgetState> emit,
  ) async {
    add(LoadBudgetSummary(month: _currentMonth));
  }
}
