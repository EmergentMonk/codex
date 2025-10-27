//! Fractal-based low-frequency oscillator suitable for modulation tasks in DSP contexts.

/// `FractalLFO` implements a quasi-periodic modulator using the midpoint displacement
/// algorithm. The fractal sequence is pre-generated for efficiency and then iterated
/// over at an audio/sample rate using linear interpolation.
pub struct FractalLFO {
    /// Normalized fractal points in the range [-1.0, 1.0].
    fractal_points: Vec<f32>,
    /// Current floating-point index within the fractal vector.
    position: f32,
    /// Normalized increment per sample derived from the requested rate.
    step: f32,
    /// Modulation depth applied to the fractal output.
    depth: f32,
    /// Sample rate used to translate the rate in Hertz to a per-sample increment.
    sample_rate: f32,
}

impl FractalLFO {
    /// Create a new `FractalLFO` with the given rate (Hz), depth, and sample rate.
    pub fn new(rate: f32, depth: f32, sample_rate: f32, iterations: usize) -> Self {
        let mut generator = FractalGenerator::new(iterations);
        let fractal_points = generator.generate();
        let step = rate / sample_rate * (fractal_points.len() as f32);

        Self {
            fractal_points,
            position: 0.0,
            step,
            depth,
            sample_rate,
        }
    }

    /// Update oscillator parameters while preserving the current position.
    pub fn set_params(&mut self, rate: f32, depth: f32) {
        self.depth = depth;
        self.step = rate / self.sample_rate * (self.fractal_points.len() as f32);
    }

    /// Retrieve the next sample of the fractal LFO signal.
    pub fn next(&mut self) -> f32 {
        let len = self.fractal_points.len() as f32;
        let integer = self.position.floor() as usize % self.fractal_points.len();
        let next_index = (integer + 1) % self.fractal_points.len();
        let frac = self.position - self.position.floor();

        let current = self.fractal_points[integer];
        let next = self.fractal_points[next_index];
        let interpolated = current + frac * (next - current);

        self.position = (self.position + self.step) % len;

        interpolated * self.depth
    }
}

/// Helper struct that generates fractal noise using midpoint displacement.
struct FractalGenerator {
    iterations: usize,
}

impl FractalGenerator {
    fn new(iterations: usize) -> Self {
        Self { iterations }
    }

    fn generate(&mut self) -> Vec<f32> {
        let mut points = vec![-1.0_f32, 1.0];
        let mut amplitude = 1.0_f32;

        for _ in 0..self.iterations {
            let mut next_points = Vec::with_capacity(points.len() * 2 - 1);

            for window in points.windows(2) {
                let left = window[0];
                let right = window[1];
                let midpoint = (left + right) * 0.5;
                let displacement = random_offset(amplitude);

                next_points.push(left);
                next_points.push((midpoint + displacement).clamp(-1.0, 1.0));
            }

            next_points.push(*points.last().unwrap());
            points = next_points;
            amplitude *= 0.5;
        }

        points
    }
}

/// Pseudo-random offset for midpoint displacement.
#[inline]
fn random_offset(scale: f32) -> f32 {
    // Simple deterministic generator using sine-based hashing.
    // For production systems replace with a RNG suitable for your requirements.
    let seed = scale.to_bits() as f32 * 12_345.6789;
    (seed.sin() * 43758.5453).sin() * scale
}
