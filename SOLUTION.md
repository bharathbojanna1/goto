# GoTo Data Science Assignment - Solution Summary

**Author:** Bharath Bojanna  
**Date:** November 18, 2025

## Executive Summary

Successfully debugged and improved the driver allocation ML pipeline for GoRide. Fixed 2 explicit bugs (NotImplementedErrors) and identified 3 critical silent bugs that would have severely impacted model validity. Implemented robust feature engineering with temporal awareness to prevent data leakage.

---

## 1. Bugs Identified and Fixed

### 1.1 Explicit Bugs (Crashed Pipeline)

**Bug #1: Missing Feature Implementation**
- **Location:** `src/features/transformations.py::driver_historical_completed_bookings()`
- **Issue:** Function raised `NotImplementedError`
- **Impact:** Pipeline crashed during feature engineering
- **Fix:** Implemented cumulative historical acceptance count per driver with proper temporal ordering to avoid data leakage

**Bug #2: Missing Evaluation Metrics**
- **Location:** `src/models/classifier.py::SklearnClassifier.evaluate()`
- **Issue:** Method raised `NotImplementedError`
- **Impact:** Pipeline crashed during model evaluation
- **Fix:** Implemented comprehensive evaluation with precision, recall, F1-score, and ROC-AUC metrics appropriate for binary classification

### 1.2 Silent Bugs (Would Not Crash But Wrong Results)

**CRITICAL Silent Bug #1: Missing Timestamp Column**
- **Location:** `src/data/make_dataset.py::clean_booking_df()`
- **Issue:** Function dropped all columns except 4 specific ones, losing `event_timestamp`
- **Impact:** Feature engineering would fail silently or use wrong temporal information
- **Root Cause:** `return df[unique_columns]` instead of `return df`
- **Fix:** Return full dataframe after deduplication
- **Why It's Serious:** This would break all time-based features without throwing an error initially

**CRITICAL Silent Bug #2: Target Variable Mislabeled**
- **Location:** `config.toml` and `src/data/make_dataset.py`
- **Issue:** Config specified `target="is_completed"` but code created target for `participant_status == "ACCEPTED"`
- **Impact:** Semantic mismatch - acceptance ≠ completion. A driver can accept but ride may still be cancelled
- **Fix:** Renamed target to `"is_accepted"` to accurately reflect what we're predicting
- **Why It's Serious:** This naming confusion could lead to wrong business conclusions about model performance

**Bug #3: Missing Random State**
- **Location:** `src/models/train_model.py::train_test_split()`
- **Issue:** No `random_state` parameter, making results non-reproducible
- **Impact:** Different runs produce different results, violating reproducibility requirement
- **Fix:** Added `random_state=33` (matching RandomForest config) to ensure reproducibility

---

## 2. Feature Engineering Approach

### 2.1 Implemented Feature: Historical Driver Acceptances

**Rationale:** Drivers with good track records are more likely to accept future bookings.

**Implementation Details:**
- Counts cumulative accepted bookings per driver *before* each current booking
- Sorts by `(driver_id, event_timestamp)` to maintain chronological order
- Subtracts current row from cumsum to avoid data leakage
- ISO timestamp format naturally sorts correctly as strings

**Data Leakage Prevention:**
```python
# WRONG: Would include current booking
df['feature'] = df.groupby('driver_id')['is_accepted'].cumsum()

# CORRECT: Only historical data
df['feature'] = df.groupby('driver_id')['is_accepted'].cumsum() - df['is_accepted']
```

### 2.2 Existing Features Validated
- `trip_distance`: Longer trips might affect acceptance
- `driver_distance`: Proximity to pickup location
- `event_hour`: Time of day patterns
- `driver_gps_accuracy`: Signal quality indicator

---

## 3. Model Evaluation Strategy

### 3.1 Metric Selection

**Primary Metrics:**
- **Precision:** Of drivers predicted to accept, how many actually do? (Reduces wasted notifications)
- **Recall:** Of drivers who accept, how many did we identify? (Maximizes successful allocations)
- **F1-Score:** Harmonic mean balancing precision/recall
- **ROC-AUC:** Overall ranking quality across thresholds

**Why These Metrics:**
The business goal is maximizing accepted orders. High precision reduces wasted notifications to unlikely acceptors. High recall ensures we don't miss willing drivers. ROC-AUC measures ranking quality since we select top-scored drivers.

### 3.2 Model Choice
**RandomForestClassifier** is appropriate because:
- Handles non-linear relationships (distance, time interactions)
- Robust to outliers and missing values
- Provides feature importances for interpretability
- No need for feature scaling
- Computationally efficient for this problem size

---

## 4. Data Quality Observations

### 4.1 Issues Noted in Data
- **Duplicate events:** Data warehouse logging duplicates (handled by `drop_duplicates`)
- **Multiple timestamps per order:** Bookings have creation, driver_found, completed events
- **Mixed formats:** Some timestamps have microseconds, some don't (handled by `robust_hour_of_iso_date`)

### 4.2 Data Validation
- Confirmed participant statuses: CREATED, ACCEPTED, IGNORED, REJECTED
- Confirmed booking statuses: CREATED, DRIVER_FOUND, COMPLETED, CANCELLED variants
- Test data has same schema as training features

---

## 5. Code Quality Improvements

1. **Reproducibility:** Added random_state throughout
2. **Documentation:** Added docstrings explaining logic and rationale
3. **Defensive Programming:** Used `.copy()` to avoid SettingWithCopyWarning
4. **Clear Semantics:** Fixed misleading variable names
5. **Type Hints:** Maintained existing type annotations
6. **Modularity:** Kept pipeline structure clean and testable

---

## 6. Potential Future Improvements

1. **Additional Features:**
   - Driver rating/score if available
   - Recent rejection rate (last N bookings)
   - Time since driver last accepted a booking
   - Driver-customer distance ratio
   - Peak hour indicator

2. **Model Enhancements:**
   - Hyperparameter tuning via GridSearchCV
   - Try XGBoost for potentially better performance
   - Ensemble multiple models
   - Class imbalance handling if acceptance rate is very low

3. **Business Logic:**
   - Consider driver capacity constraints
   - Factor in customer waiting time
   - Multi-objective optimization (acceptance rate + completion rate)

---

## 7. Key Takeaways

### 7.1 Most Impactful Fixes
1. **Missing timestamp column** - Would have broken feature engineering completely
2. **Target variable semantics** - Ensured we're solving the right problem
3. **Data leakage prevention** - Historical features properly exclude current data

### 7.2 Lessons Learned
- **Silent bugs are dangerous:** Code runs but produces wrong results
- **Semantic clarity matters:** Variable names should match their meaning
- **Reproducibility is critical:** Always set random seeds
- **Data quality vigilance:** Real-world data has issues that need handling
- **Business understanding first:** Know what you're predicting and why

---

## 8. Reproducibility Checklist

✅ Random state set for train/test split  
✅ Random state set for RandomForest  
✅ Data processing order deterministic  
✅ Dependencies specified in requirements.txt  
✅ Clear execution order in Makefile  
✅ Results validated against expected schema  

---

**Conclusion:** The pipeline now runs end-to-end with proper data handling, no data leakage, reproducible results, and appropriate evaluation metrics. The model predicts driver acceptance probability to optimize booking allocation, directly addressing the business objective of maximizing accepted orders in the GoRide system.
