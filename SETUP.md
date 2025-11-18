# Setup and Run Instructions

## Current Progress
- ✅ Fixed NotImplementedError in driver_historical_completed_bookings
- ✅ Fixed NotImplementedError in evaluate method
- ✅ Fixed CRITICAL BUG: clean_booking_df dropping event_timestamp
- ✅ Added driver_completed_bookings to config features

## Running the Pipeline

### Option 1: Using Make (requires conda/pyenv)
```bash
make setup_env
make run
```

### Option 2: Using Python directly
```bash
# Create virtual environment
python -m venv venv
venv\Scripts\activate  # Windows
# or
source venv/bin/activate  # Linux/Mac

# Install dependencies
pip install -r requirements.txt

# Run pipeline steps
python -m src.data.make_dataset
python -m src.features.build_features
python -m src.models.train_model
python -m src.models.predict_model

# Run tests
pytest test/
```

## Next Steps
1. Try running pipeline to find remaining bugs
2. Check for silent/subtle issues
3. Improve model performance
4. Write SOLUTION.md
