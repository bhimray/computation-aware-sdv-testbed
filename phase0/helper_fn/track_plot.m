trackData = readmatrix("LMS_Track.txt");

track.s_m = trackData(:,1);
track.X_ref_m = trackData(:,2);
track.Y_ref_m = trackData(:,3);
track.psi_ref_rad = trackData(:,4);
track.curvature_1pm = trackData(:,5);

figure;
plot(track.X_ref_m, track.Y_ref_m, "LineWidth", 1.5);
axis equal;
grid on;
xlabel("X (m)");
ylabel("Y (m)");
title("LMS Reference Track");