"""
BusSense AI - CV Pipeline Evaluation Script (Phase H18)
Executes empirical benchmarking of the computer vision occupancy pipeline across 6 transit operational scenarios.
Generates metrics for MAE, RMSE, MAPE, precision, recall, latency (mean & P95), FPS, stabilization gain, and verifies zero-biometrics privacy.
"""
import sys
import os
import json
from pathlib import Path

# Add backend directory to sys.path
backend_dir = Path(__file__).resolve().parent.parent / "backend"
sys.path.insert(0, str(backend_dir))

from cv.evaluator import cv_evaluator

def main():
    print("=" * 80)
    print(" BusSense AI - Computer Vision Pipeline Empirical Evaluation (Phase H18)")
    print(" Privacy Standard: Zero Biometrics (Head/Body Counts Only)")
    print("=" * 80)

    report = cv_evaluator.run_full_evaluation(seed=42)

    print(f"\nTotal Scenarios Evaluated:       {report.total_scenarios_evaluated}")
    print(f"Dataset Partition:               {report.dataset_partition}")
    print(f"Overall Zero-Biometrics Audit:   {'PASSED (Zero facial/biometric data)' if report.overall_zero_biometrics_passed else 'FAILED'}")
    print(f"Aggregate Raw MAE:               {report.aggregate_raw_mae:.2f} passengers")
    print(f"Aggregate Smoothed MAE:          {report.aggregate_smoothed_mae:.2f} passengers")
    print(f"Temporal Smoothing Error Gain:   +{report.stabilization_improvement_pct:.1f}% accuracy improvement")
    print(f"Aggregate Smoothed RMSE:         {report.aggregate_smoothed_rmse:.2f} passengers")
    print(f"Aggregate Mean Absolute Pct Err: {report.aggregate_mape_pct:.2f}%")
    print(f"Aggregate Precision:             {report.aggregate_precision:.3f}")
    print(f"Aggregate Recall:                {report.aggregate_recall:.3f}")
    print(f"Aggregate F1-Score:              {report.aggregate_f1_score:.3f}")
    print(f"Mean Pipeline Latency:           {report.aggregate_inference_ms:.2f} ms")
    print(f"P95 Pipeline Latency:            {report.aggregate_p95_inference_ms:.2f} ms")
    print(f"Effective Processing Throughput: {report.aggregate_fps:.1f} FPS")

    print("\n" + "-" * 105)
    print(f"{'Scenario Name':<22} | {'GT':<4} | {'Raw MAE':<7} | {'Smooth MAE':<10} | {'RMSE':<5} | {'MAPE':<6} | {'Prec':<5} | {'Rec':<5} | {'P95 ms':<7} | {'FPS':<5}")
    print("-" * 105)

    for s in report.scenario_results:
        print(f"{s.scenario_name:<22} | {s.ground_truth_mean:<4.1f} | {s.raw_mae:<7.2f} | {s.smoothed_mae:<10.2f} | {s.smoothed_rmse:<5.2f} | {s.mape_pct:<5.1f}% | {s.precision:<5.2f} | {s.recall:<5.2f} | {s.p95_inference_ms:<7.1f} | {s.processing_fps:<5.1f}")

    print("-" * 105)
    print(f"\nPrivacy Guarantee Audit:\n{report.privacy_audit_summary}")
    print("=" * 80)

    # Save output report to docs/
    h19_path = Path(__file__).resolve().parent.parent / "docs" / "cv_evaluation_h19.json"
    with open(h19_path, "w") as f:
        json.dump(report.model_dump(), f, indent=2)
    print(f"\nSaved Phase H19 CV evaluation report to: {h19_path}")

    h18_path = Path(__file__).resolve().parent.parent / "docs" / "cv_evaluation_h18.json"
    with open(h18_path, "w") as f:
        json.dump(report.model_dump(), f, indent=2)

    h17_path = Path(__file__).resolve().parent.parent / "docs" / "cv_evaluation_h17.json"
    with open(h17_path, "w") as f:
        json.dump(report.model_dump(), f, indent=2)

if __name__ == "__main__":
    main()

