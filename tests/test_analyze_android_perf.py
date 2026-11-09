"""Offline parser QA. No emulator, app state, or gameplay save is accessed."""

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))

from analyze_android_perf import choose_pid, markdown, parse_records, percentile, summarize


class AndroidPerfAuditTest(unittest.TestCase):
    def setUp(self):
        self.records = parse_records("""
I/godot   ( 111): KEBUN_PERF fps=19 process_ms=89.0 draw_calls=330 static_mb=59.0 tab=kebun
I/godot   ( 111): KEBUN_PERF fps=20 process_ms=91.0 draw_calls=328 static_mb=59.0 tab=kebun
I/godot   ( 111): KEBUN_LAYER_PROBE starting=baseline
I/godot   ( 111): KEBUN_LAYER_PROBE mode=baseline fps=19.0 draw_calls=330.0 process_ms=90.0 samples=100
I/godot   ( 222): KEBUN_PERF fps=27 process_ms=55.0 draw_calls=280 static_mb=61.0 tab=kebun
I/godot   ( 111): KEBUN_TICK avg_ms=2.50 camera=0.10
W/unrelated( 222): KEBUN_PERF fps=999 process_ms=0 draw_calls=0 static_mb=0
I/godot   ( 222): KEBUN_DRAW total_ms=0.3 misc=0.2
""")

    def test_latest_session_is_pid_of_last_perf_sample(self):
        self.assertEqual(choose_pid(self.records), 222)
        self.assertEqual(summarize(self.records, 222)["metrics"]["PERF"]["fps"]["n"], 1)

    def test_mixed_sessions_cannot_inflate_statistics(self):
        old = summarize(self.records, 111)
        self.assertEqual(old["metrics"]["PERF"]["fps"]["median"], 19.5)
        self.assertEqual(old["metrics"]["PERF"]["draw_calls"]["min"], 328)
        self.assertEqual(old["probes"][0]["samples"], 100)
        self.assertIn("baseline", markdown(old))

    def test_percentiles_and_missing_fields(self):
        self.assertEqual(percentile([1, 2, 3, 4], 0.9), 3.7)
        self.assertEqual(len(self.records), 7)
        with self.assertRaisesRegex(ValueError, "PID"):
            choose_pid(self.records, 999)
        with self.assertRaisesRegex(ValueError, "Tidak ditemukan"):
            choose_pid([])


if __name__ == "__main__":
    unittest.main()
