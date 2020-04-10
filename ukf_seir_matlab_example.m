clear; clc

N = 6939373;        % population of massachusetts

% Initial state guess.
                    %S; E; I; R; beta
initialStateGuess = [N; 0; 2; 0; 2.2];

% Construct the filter
ukf = unscentedKalmanFilter(...
    @seirStateFcn,...                % State transition function
    @seirMeasurementFcn,...          % Measurement function 
    initialStateGuess, ...
    'HasAdditiveProcessNoise', true);

% Define noise terms.
RI = 100;                           % Variance of the measurement noise in I
ukf.MeasurementNoise = diag([RI]);
                                    % Process noise.
ukf.ProcessNoise = diag([1e5 1e5 10 10 0.01]);

% Load the measurements
load('/Users/mak/Dropbox (BOSTON UNIVERSITY)/Research/COVID/covid_analysis/MA.mat');
yMeas      = I;
timeVector = (1:length(I));

% Perform the filtering

Nsteps        = length(yMeas);      % Number of time steps
xCorrectedUKF = zeros(Nsteps,5);    % Corrected state estimates
PCorrected    = zeros(Nsteps,5,5);  % Corrected state estimation error covariances
e = zeros(Nsteps,1);                % Residuals (or innovations)

for k=1:Nsteps
    % Let k denote the current time.
    % Residuals (or innovations): Measured output - Predicted output
    e(k) = yMeas(k) - seirMeasurementFcn(ukf.State); % ukf.State is x[k|k-1] at this point
    
    % Incorporate the measurements at time k into the state estimates by
    % using the "correct" command. This updates the State and StateCovariance
    % properties of the filter to contain x[k|k] and P[k|k]. These values
    % are also produced as the output of the "correct" command.
    [xCorrectedUKF(k,:), PCorrected(k,:,:)] = correct(ukf,yMeas(k));
    
    % Predict the states at next time step, k+1. This updates the State and
    % StateCovariance properties of the filter to contain x[k+1|k] and
    % P[k+1|k]. These will be utilized by the filter at the next time step.
    predict(ukf);
    day_label{k} = string(datetime(d(k,[3,1,2])));
end

% Predict the future.
future_days = Nsteps;                 % Steps in the future
xPredictedUKF = zeros(future_days,5); % Corrected state estimates
for k=1:future_days
    predict(ukf);
    xPredictedUKF(k,:) = ukf.State;
end
day_label_future = string(datetime(d(end,[3,1,2]),'Format','dd-MMM-yyyy')+days(1:future_days))

%figure();
labels = {'x_1,S'; 'x_2,E'; 'x_3,I'; 'x_4,R'; 'x_5,beta'};
for k=1:5
    subplot(5,1,k);
    plot(timeVector,xCorrectedUKF(:,k));
    hold on
    plot(timeVector(end)+(1:future_days), xPredictedUKF(:,k))
    hold off
    ylabel(labels{k});
    axis tight
end
subplot(5,1,3)
hold on
plot(timeVector,yMeas, 'o');
hold off
set(gca, 'XTick', (1:timeVector(end)+future_days))
set(gca, 'XTickLabel', [day_label,day_label_future])
xtickangle(90)

