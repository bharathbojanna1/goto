from abc import ABC, abstractmethod
from typing import Dict, List

import numpy as np
import pandas as pd
from sklearn.base import BaseEstimator


class Classifier(ABC):
    @abstractmethod
    def train(self, *params) -> None:
        pass

    @abstractmethod
    def evaluate(self, *params) -> Dict[str, float]:
        pass

    @abstractmethod
    def predict(self, *params) -> np.ndarray:
        pass


class SklearnClassifier(Classifier):
    def __init__(
        self, estimator: BaseEstimator, features: List[str], target: str,
    ):
        self.clf = estimator
        self.features = features
        self.target = target

    def train(self, df_train: pd.DataFrame):
        self.clf.fit(df_train[self.features].values, df_train[self.target].values)

    def evaluate(self, df_test: pd.DataFrame):
        """
        Evaluate model performance using multiple classification metrics.
        
        For driver allocation, we care about:
        - Precision: Of drivers we predict will accept, how many actually do?
        - Recall: Of drivers who actually accept, how many did we identify?
        - F1: Harmonic mean balancing precision and recall
        - ROC-AUC: Overall ranking quality across thresholds
        """
        from sklearn.metrics import precision_score, recall_score, f1_score, roc_auc_score
        
        y_true = df_test[self.target].values
        y_pred_proba = self.clf.predict_proba(df_test[self.features].values)[:, 1]
        y_pred = (y_pred_proba >= 0.5).astype(int)
        
        metrics = {
            "precision": float(precision_score(y_true, y_pred, zero_division=0)),
            "recall": float(recall_score(y_true, y_pred, zero_division=0)),
            "f1_score": float(f1_score(y_true, y_pred, zero_division=0)),
            "roc_auc": float(roc_auc_score(y_true, y_pred_proba))
        }
        
        return metrics

    def predict(self, df: pd.DataFrame):
        return self.clf.predict_proba(df[self.features].values)[:, 1]
