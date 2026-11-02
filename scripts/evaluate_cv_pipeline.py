"""
BusSense AI - CV Pipeline Evaluation Script (Phase H17)
Executes empirical benchmarking of the computer vision occupancy pipeline across 6 transit operational scenarios.
Generates metrics for MAE, RMSE, FPS, stabilization gain, and verifies zero-biometrics privacy.
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
    print(" BusSense AI - Computer Vision Pipeline Empirical Evaluation (Phase H17)")
    print(" Privacy Standard: Zero Biometrics (Head/Body Counts Only)")
    print("=" * 80)

    report = cv_evaluator.run_full_evaluation(seed=42)

    print(f"\nTotal Scenarios Evaluated: {report.total_scenarios_evaluated}")
    print(f"Overall Zero-Biometrics Compliance: {'PASSED (Zero facial/biometric data)' if report.overall_zero_biometrics_passed else 'FAILED'}")
    print(f"Aggregate Raw MAE:               {report.aggregate_raw_mae:.2f} passengers")
    print(f"Aggregate Smoothed MAE:          {report.aggregate_smoothed_mae:.2f} passengers")
    print(f"Temporal Smoothing Error Gain:   +{report.stabilization_improvement_pct:.1f}% accuracy improvement")
    print(f"Aggregate Smoothed RMSE:         {report.aggregate_smoothed_rmse:.2f} passengers")
    print(f"Mean Pipeline Latency:           {report.aggregate_inference_ms:.2f} ms")
    print(f"Effective Processing Throughput: {report.aggregate_fps:.1f} FPS")

    print("\n" + "-" * 80)
    print(f"{'Scenario Name':<24} | {'GT Mean':<8} | {'Raw MAE':<8} | {'Smooth MAE':<11} | {'RMSE':<6} | {'FPS':<6} | {'Stability':<9}")
    print("-" * 80)

    for s in report.scenario_results:
        print(f"{s.scenario_name:<24} | {s.ground_truth_mean:<8.1f} | {s.raw_mae:<8.2f} | {s.smoothed_mae:<11.2f} | {s.smoothed_rmse:<6.2f} | {s.processing_fps:<6.1f} | {s.detection_stability_pct:<8.1f}%")

    print("-" * 80)
    print(f"\nPrivacy Guarantee Audit:\n{report.privacy_audit_summary}")
    print("=" * 80)

    # Save output report to docs/
    report_path = Path(__file__).resolve().parent.parent / "docs" / "cv_evaluation_h17.json"
    with open(report_path, "w") as f:
        json.dump(report.model_dump(), f, indent=2)
    print(f"\nSaved empirical CV evaluation report to: {report_path}")

if __name__ == "__main__":
    main()

