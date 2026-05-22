# SpendArc — Personal Finance Tracker

A production-grade Flutter app demonstrating Clean Architecture, custom animations, BLoC, and offline-first patterns.

## Architecture

```
lib/
├── core/
│   ├── di/              # GetIt dependency injection
│   ├── error/           # Failures + Exceptions
│   ├── network/         # NetworkInfo (connectivity_plus)
│   ├── router/          # GoRouter deep links
│   ├── theme/           # AppTheme + AppColors
│   ├── usecases/        # UseCase abstractions
│   └── utils/           # CurrencyFormatter, DateFormatter
├── data/
│   ├── datasources/
│   │   ├── local/       # SQLite (sqflite) + WriteQueue
│   │   └── remote/      # Dio REST client
│   ├── models/          # TransactionModel (extends entity)
│   └── repositories/    # TransactionRepositoryImpl
├── domain/
│   ├── entities/        # Transaction, BudgetSummary, ChartData
│   ├── repositories/    # Abstract TransactionRepository
│   └── usecases/        # GetTransactions, Add, Delete, Update, Budget, Chart
└── presentation/
    ├── blocs/           # TransactionsBloc, BudgetBloc, SyncBloc
    ├── screens/         # Home, Budget, Analytics, AddTransaction
    └── widgets/
        └── animations/  # ArcMeter, LineChart, ParticleBurst, SpringSwipe
```

## Modules

| Module | What it covers |
|--------|---------------|
| **Clean Architecture** | Layer purity, GetIt DI, `Either<Failure, T>`, UseCase abstraction |
| **Custom Animations** | `ArcMeterPainter` (CustomPainter gauge), `LineChartPainter` (scratch chart), `SpringSwipeDelete` (physics), `ParticleBurst` |
| **BLoC** | Optimistic updates + rollback, inter-bloc communication, proper disposal |
| **Offline-First** | Instant local load, background sync, write queue, Isolate computation |
| **Testing** | 5 unit tests (model + bloc), 2 widget tests |
| **Bonus: GLSL Shader** | `aurora.frag` — animated aurora background |
| **Bonus: GoRouter** | Deep links: `spendarc://add`, `spendarc://edit/:id`, etc. |

## Setup

```bash
flutter pub get
flutter run
```

## Run tests

```bash
flutter test
```

<img width="1344" height="2992" alt="image" src="https://github.com/user-attachments/assets/d48ec595-692c-4ac5-99e7-81f136a751b9" />
<img width="1344" height="2992" alt="image" src="https://github.com/user-attachments/assets/05a61a52-f6b2-4e0e-a7e7-aa15f53980f4" />
<img width="1344" height="2992" alt="image" src="https://github.com/user-attachments/assets/f34ff771-3bf5-45fb-8912-30dd7c1c4037" />
<img width="1344" height="2992" alt="image" src="https://github.com/user-attachments/assets/585e21b2-bd9d-4605-a322-17cf6feb0cbd" />





