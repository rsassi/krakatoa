package directoryReport;

import java.text.DecimalFormat;

public class DirectoryCoverage {
    int fexeccount;
    int fcount;

    DirectoryCoverage(int fexeccount, int fcount) {
        this.fexeccount = fexeccount;
        this.fcount = fcount;
    }

    DirectoryCoverage(String name) {
        this.fexeccount = 0;
        this.fcount = 0;
    }

    double functionCoverage() {
        double coverage = 0.0;
        if (fcount != 0) {
            coverage = 100.0 * fexeccount / fcount;
        }
        return coverage;
    }

    String functionCoverageAsString() {
        DecimalFormat decimalFormat = new DecimalFormat("0.000");
        decimalFormat.setRoundingMode(java.math.RoundingMode.HALF_UP);
        return decimalFormat.format(functionCoverage());
    }

    public String toString() {
        return "{ functions(" + fcount + "), fexecuted(" + fexeccount
                + "), cov(" + functionCoverage() + ")}";
    }

}
