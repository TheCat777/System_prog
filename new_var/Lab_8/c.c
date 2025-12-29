#include <iostream>
#include <cmath>

int depth;

int estimate_depth(double x, double epsilon){
    if (x < epsilon){
        return 1;
    }
    double x_squared = x * x;

    int n = 1;
    double remainder, error_estimate;
    while (true){
        remainder = x_squared / ((2 * n + 1) * (2 * n + 3));
        error_estimate = fabs(remainder * x / (1 - remainder));
        if (error_estimate < epsilon){
            break;
        }
        ++n;
    }
    return n;
}

double continued_fraction_tan(double x, double epsilon, int max_depth = -1){
    if (fabs(x) < epsilon){
        depth = 1;
        return x;
    }
    int estimated_depth;
    if (max_depth == -1){
        max_depth = estimate_depth(x, epsilon);
    }
    double x_squared = x * x;
    double current_value = 2 * max_depth + 1;

    for (int n = max_depth; n > 0; --n){
        double denominator = 2 * n + 1;
        current_value = denominator - x_squared / current_value;
    }

    double result = x / (1 - x_squared / current_value);
    double next_term = x_squared / (2 * max_depth + 1);
    double actual_error = fabs(next_term * result / (1 - next_term));

    if (actual_error > epsilon){
        depth = max_depth * 2;
        return continued_fraction_tan(x, epsilon, max_depth * 2);
    }
    depth = max_depth;
    return result;
}

int main() {
    double result = continued_fraction_tan(1, 0.001, -1);
    printf("%.10f   %d", result, depth);
}