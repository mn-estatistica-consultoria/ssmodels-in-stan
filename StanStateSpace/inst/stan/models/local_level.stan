functions {
  #include ssm.stan
}
data {
  int<lower = 1> n;
  vector[1] y[n];
  vector<lower = 0.0>[1] a1;
  cov_matrix[1] P1;
  real<lower = 0.0> y_scale;
}
transformed data {
  // system matrices
  matrix[1, 1] T;
  matrix[1, 1] Z;
  matrix[1, 1] R;
  vector[1] c;
  vector[1] d;
  int m;
  int p;
  int q;
  int filter_sz;
  m = 1;
  p = 1;
  q = 1;
  T[1, 1] = 1.0;
  Z[1, 1] = 1.0;
  R[1, 1] = 1.0;
  c[1] = 0.0;
  d[1] = 0.0;
  filter_sz = ssm_filter_size(m, p);
}
parameters {
  real<lower = 0.0> sigma_eta;
  real<lower = 0.0> sigma_epsilon;
}
transformed parameters {
  matrix[1, 1] H;
  matrix[1, 1] Q;
  H = rep_matrix(pow(sigma_epsilon, 2), 1, 1);
  Q = rep_matrix(pow(sigma_eta * sigma_epsilon, 2), 1, 1);
}
model {
  y ~ ssm_lpdf(rep_array(d, 1), rep_array(Z, 1),
               rep_array(H, 1), rep_array(c, 1),
               rep_array(T, 1), rep_array(R, 1),
               rep_array(Q, 1), a1, P1);
  sigma_epsilon ~ cauchy(0.0, y_scale);
  sigma_eta ~ cauchy(0.0, 1.0);
}
generated quantities {
  vector[filter_sz] filtered[n];
  vector[2] eta[n];
  vector[2] eps[n];
  vector[2] alpha[n];
  vector[1] alpha2[n];
  vector[1] alphar[n];
  vector[1] etar[n];
  vector[1] epsr[n];
  // Filtered data
  filtered = ssm_filter(y,
                        rep_array(d, 1), rep_array(Z, 1), rep_array(H, 1),
                        rep_array(c, 1), rep_array(T, 1), rep_array(R, 1),
                        rep_array(Q, 1), a1, P1);
  // smoothed values
  alpha = ssm_smooth_state(filtered, rep_array(Z, 1), rep_array(T, 1));
  eps = ssm_smooth_eps(filtered, rep_array(Z, 1), rep_array(H, 1),
                         rep_array(T, 1));
  eta = ssm_smooth_eta(filtered, rep_array(Z, 1), rep_array(T, 1),
                       rep_array(R, 1), rep_array(Q, 1));
  alpha2 = ssm_smooth_state_mean(filtered, rep_array(Z, 1), rep_array(c, 1),
    rep_array(T, 1), rep_array(R, 1), rep_array(Q, 1));
  // sampling states
  alphar = ssm_simsmo_states_rng(filtered,
                        rep_array(d, 1), rep_array(Z, 1), rep_array(H, 1),
                        rep_array(c, 1), rep_array(T, 1), rep_array(R, 1), rep_array(Q, 1),
                        a1, P1);
  // sampling state disturbances
  etar = ssm_simsmo_eta_rng(filtered,
                        rep_array(d, 1), rep_array(Z, 1), rep_array(H, 1),
                        rep_array(c, 1), rep_array(T, 1), rep_array(R, 1), rep_array(Q, 1),
                        a1, P1);
  // sampling observation disturbances
  epsr = ssm_simsmo_eps_rng(filtered,
                        rep_array(d, 1), rep_array(Z, 1), rep_array(H, 1),
                        rep_array(c, 1), rep_array(T, 1), rep_array(R, 1), rep_array(Q, 1),
                        a1, P1);

}
