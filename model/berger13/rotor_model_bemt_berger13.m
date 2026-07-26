function [Fbody, Mbody, out] = rotor_model_bemt_berger13( ...
        x, rotorCtrl, betaM, side, cgShift, P, lateralMapping)
%ROTOR_MODEL_BEMT_BERGER13 Isolated PR1 rotor with opt-in lateral cyclic.
% This file is a namespace-local copy of the NUAA physical-baseline rotor
% at 3550e5b855bac1c38e9d275cf3f8e608cb519c70.  The only aerodynamic
% extension is theta1c = rotDir*lateralCyclic, selectively adapted from
% the research source at 370c7aef13a5dca98c0436616548729859c399a9.
% The production rotor_model_bemt.m and its legacy seven-input path are not
% modified by PR1.
%
% side = -1: left rotor; side = +1: right rotor.
% rotorCtrl.collective: side collective pitch, rad.
% rotorCtrl.cyclicLong: side longitudinal cyclic command, rad. Internally it
% is mapped to theta1s = -rotDir*rotorCtrl.cyclicLong so positive common
% cyclic tilts both disk normals toward +eD under the current psi definition.
% rotorCtrl.lateralCyclic: symmetric lateral cyclic command, rad.  It is
% mapped only in this research namespace and is not a legacy public input.
%
% The flapping model is a minimum steady first-harmonic center-hinge model:
%   beta = beta0 + beta1c*cos(psi) + beta1s*sin(psi).
% Aerodynamic flap moment uses r*dT as a small-flapping-angle normal-force
% approximation. rootCut is only the aerodynamic integration start; it is
% not a flapping-hinge offset.

x = x(:);
Vbody = x(1:3);
omegaBody = x(4:6);
phiBody = x(7);
thetaBody = x(8);

if ~(side == -1 || side == 1)
    error('side must be -1 (left) or +1 (right).');
end

rotDir = side;

if nargin < 7 || isempty(lateralMapping)
    lateralMapping = 'rotDir';
end
if ~strcmp(lateralMapping, 'rotDir')
    error('rotor_model_bemt_berger13:InvalidLateralMapping', ...
        'PR1 supports only the reviewed rotDir lateral-cyclic mapping.');
end
if ~isfield(rotorCtrl, 'lateralCyclic') || ...
        isempty(rotorCtrl.lateralCyclic)
    rotorCtrl.lateralCyclic = 0;
end
theta1cCommand = rotDir*rotorCtrl.lateralCyclic;

% betaM = 0: helicopter mode, thrust upward. betaM = pi/2: airplane mode,
% thrust forward. eD and eY span the nominal rotor disk.
eT = [sin(betaM); 0; -cos(betaM)];
eD = [cos(betaM); 0;  sin(betaM)];
eY = [0; 1; 0];

rHub0 = [P.rotor.pivotX + P.rotor.RH_hub*sin(betaM);
         side*P.rotor.pivotY;
         P.rotor.pivotZ - P.rotor.RH_hub*cos(betaM)];

rHub = rHub0 - cgShift;
Vhub = Vbody + cross(omegaBody, rHub);

Vaxial = dot(Vhub, eT);
Vlong  = dot(Vhub, eD);
Vlat   = dot(Vhub, eY);

tipSpeed = P.rotor.Omega * P.rotor.R;
muLong = Vlong / max(tipSpeed, eps);
muLat  = Vlat  / max(tipSpeed, eps);
mu = hypot(Vlong, Vlat) / max(tipSpeed, eps);

A = pi*P.rotor.R^2;
vi = sqrt(max(P.mass.m*P.env.g/2, 1)/(2*P.env.rho*A));
zFlap = P.rotor.flapInitial(:);

if numel(zFlap) ~= 3
    error('P.rotor.flapInitial must contain [beta0; beta1c; beta1s].');
end

coupledConverged = false;
viError = Inf;
flapInfo = struct();
positiveThrustGuardEverActive = false;
eq13 = struct('CT',NaN,'mu',mu,'lambda0',NaN,'lambda1',NaN, ...
    'target',NaN,'old',NaN,'new',NaN,'positiveThrustGuardActive',false, ...
    'denominatorFloorActive',false);

for iter = 1:P.rotor.inducedMaxIter
    [zFlap, flapInfo] = solve_flap(vi, zFlap);
    if ~flapInfo.converged
        error('rotor_model_bemt:FlapNotConverged', ...
            'Flapping solve did not converge for side %+d.', side);
    end

    loads = blade_loads(vi, zFlap);

    % NUAA Eq. (13) in the current rotor-axis sign convention.
    % CT uses 0.5*rho*A*(Omega R)^2 so that
    % tipSpeed*CT/(4*sqrt(lambda1^2+mu^2)) is algebraically equivalent to
    % T/(2*rho*A*sqrt(Vplane^2 + (Vaxial+vi)^2)) for positive thrust.
    % lambda0=-Vaxial/tipSpeed maps positive body velocity along +eT to a
    % negative inflow ratio; lambda1=lambda0-vi/tipSpeed includes induced
    % velocity with the existing positive-thrust convention.
    lambda0 = -Vaxial / max(tipSpeed, eps);
    lambda1 = lambda0 - vi / max(tipSpeed, eps);
    CT = max(loads.T, 0)/(0.5*P.env.rho*A*tipSpeed^2);
    denomEq13 = sqrt(lambda1^2 + mu^2);
    denomEq13Used = max(denomEq13, 1.0e-12);
    viTarget = tipSpeed*CT/(4*denomEq13Used);

    viNew = 0.5*(vi + viTarget);
    viError = abs(viNew - vi)/max(1, abs(vi));

    eq13.CT = CT;
    eq13.mu = mu;
    eq13.lambda0 = lambda0;
    eq13.lambda1 = lambda1;
    eq13.target = viTarget;
    eq13.old = vi;
    eq13.new = viNew;
    eq13.positiveThrustGuardActive = loads.T < 0;
    eq13.denominatorFloorActive = denomEq13 < denomEq13Used;
    positiveThrustGuardEverActive = positiveThrustGuardEverActive || ...
        eq13.positiveThrustGuardActive;

    vi = viNew;
    if viError < P.rotor.inducedTol && ...
            flapInfo.residualNorm <= P.rotor.flapResidualTol
        coupledConverged = true;
        break;
    end
end

if ~coupledConverged
    error('rotor_model_bemt:CoupledSolveNotConverged', ...
        ['Coupled induced-velocity/flapping solve did not converge ' ...
         'for side %+d. viError=%.3e, flapResidual=%.3e.'], ...
        side, viError, flapInfo.residualNorm);
end

loads = blade_loads(vi, zFlap);
lambda0Final = -Vaxial/max(tipSpeed, eps);
lambda1Final = lambda0Final-vi/max(tipSpeed, eps);
denomFinal = sqrt(lambda1Final^2+mu^2);
denomFinalUsed = max(denomFinal, 1e-12);
CTFinal = max(loads.T,0)/(0.5*P.env.rho*A*tipSpeed^2);
momentumThrust = 2*P.env.rho*A*tipSpeed*vi*denomFinal;
closureResidual = loads.T-momentumThrust;
closureScale = max([abs(loads.T), abs(momentumThrust), 1]);
closureResidualRelative = abs(closureResidual)/closureScale;
inducedSequenceConverged = viError < P.rotor.inducedTol;
flapConverged = flapInfo.converged && ...
    flapInfo.residualNorm <= P.rotor.flapResidualTol;
% DIMENSIONLESS_AUDIT_CRITERION. This is a load-closure acceptance
% threshold, not the dimensional induced-velocity iteration tolerance.
% The factor two mirrors the half-relaxed fixed-point update.
closureResidualRelativeTolerance = 2.0e-4;
closureResidualSatisfied = closureResidualRelative <= ...
    closureResidualRelativeTolerance;
positiveThrustGuardActive = loads.T < 0;
physicalBranchSupported = loads.T > 0;
physicalConverged = coupledConverged && closureResidualSatisfied && ...
    physicalBranchSupported;
if loads.T < 0
    physicalStatus = 'UNSUPPORTED_NEGATIVE_THRUST_BRANCH';
elseif loads.T == 0
    physicalStatus = 'UNSUPPORTED_ZERO_THRUST_BRANCH';
elseif ~closureResidualSatisfied
    physicalStatus = 'INDUCED_CLOSURE_RESIDUAL_NOT_SATISFIED';
elseif ~coupledConverged
    physicalStatus = 'NUMERICAL_ITERATION_NOT_CONVERGED';
else
    physicalStatus = 'PHYSICAL_CONVERGED';
end

beta0 = zFlap(1);
beta1c = zFlap(2);
beta1s = zFlap(3);

nDiskRaw = eT - beta1c*eD - beta1s*eY;
nDisk = nDiskRaw / norm(nDiskRaw);

Fbody = loads.T*nDisk + loads.Hlong*eD + loads.Hlat*eY;

Mreaction = -rotDir*loads.Q*eT;

Hrot = rotDir*P.rotor.Jpolar*P.rotor.Omega*eT;
Mgyro = -cross(omegaBody, Hrot);
Marm = cross(rHub, Fbody);

Mbody = Marm + Mreaction + Mgyro;

out.side = side;
out.rotDir = rotDir;
out.rHub = rHub;
out.Vhub = Vhub;
out.Vaxial = Vaxial;
out.Vlong = Vlong;
out.Vlat = Vlat;
out.muLong = muLong;
out.muLat = muLat;
out.beta0 = beta0;
out.beta1c = beta1c;
out.beta1s = beta1s;
out.zFlap = zFlap;
out.theta1c = theta1cCommand;
out.theta1s = -rotDir*rotorCtrl.cyclicLong;
out.eT = eT;
out.eD = eD;
out.eY = eY;
out.basisOrthogonalityError = max(max(abs([eT,eD,eY].'*[eT,eD,eY] - eye(3))));
out.nDisk = nDisk;
out.eTeff = nDisk;
out.thrust = loads.T;
out.torque = loads.Q;
out.Hlong = loads.Hlong;
out.Hlat = loads.Hlat;
out.Marm = Marm;
out.Mreaction = Mreaction;
out.Hrot = Hrot;
out.Mgyro = Mgyro;
out.minUT = loads.minUT;
out.maxUT = loads.maxUT;
out.maxAbsAlphaBlade = loads.maxAbsAlphaBlade;
out.inducedVelocity = vi;
out.inducedVelocityError = viError;
out.inducedVelocityTargetEq13 = eq13.target;
out.inducedVelocityUpdateOld = eq13.old;
out.inducedVelocityUpdateNew = eq13.new;
out.inducedVelocityUpdateWeight = 0.5;
out.CT = eq13.CT;
out.CTFinal = CTFinal;
out.mu = eq13.mu;
out.lambda0 = eq13.lambda0;
out.lambda1 = eq13.lambda1;
out.lambda0Final = lambda0Final;
out.lambda1Final = lambda1Final;
out.inducedClosureModel = 'NUAA_EQ13';
out.positiveThrustGuardActive = positiveThrustGuardActive;
out.positiveThrustGuardEverActive = positiveThrustGuardEverActive;
out.inducedDenominatorFloorActive = eq13.denominatorFloorActive;
out.inducedDenominatorFloorActiveFinal = denomFinal < denomFinalUsed;
out.inducedMomentumThrust = momentumThrust;
out.inducedClosureResidual = closureResidual;
out.inducedClosureResidualRelative = closureResidualRelative;
out.inducedClosureResidualRelativeTolerance = ...
    closureResidualRelativeTolerance;
out.inducedSequenceConverged = inducedSequenceConverged;
out.flapConverged = flapConverged;
out.closureResidualSatisfied = closureResidualSatisfied;
out.physicalBranchSupported = physicalBranchSupported;
out.physicalConverged = physicalConverged;
out.physicalStatus = physicalStatus;
out.inflowModel = loads.inflowModel;
out.inducedVelocityField = loads.viField;
out.inducedVelocityFieldMin = loads.viFieldMin;
out.inducedVelocityFieldMax = loads.viFieldMax;
out.inducedVelocityFieldAzimuthMeanError = loads.viFieldAzimuthMeanError;
out.inducedVelocityFieldPsi = loads.psi;
out.inducedVelocityFieldRadius = loads.rMid;
out.iterations = iter;
% Backward-compatible numerical flag. Physical acceptance must use
% out.physicalConverged and out.physicalStatus.
out.coupledConverged = coupledConverged;
out.numericalConverged = coupledConverged;
out.flap = flapInfo;
out.F = Fbody;
out.M = Mbody;

    function [z, info] = solve_flap(viMean, z0)
        z = z0(:);
        info = struct();
        info.converged = false;
        info.iterations = 0;
        info.residual = NaN(3,1);
        info.residualNorm = Inf;
        info.scale = NaN;
        info.exitStatus = 'not_started';

        for k = 1:P.rotor.flapMaxIter
            [R, aux] = flap_residual(z, viMean);
            Rn = R / aux.scale;
            nR = norm(Rn);

            info.iterations = k;
            info.residual = R;
            info.residualNorm = nR;
            info.scale = aux.scale;

            if nR <= P.rotor.flapResidualTol
                info.converged = true;
                info.exitStatus = 'converged';
                info.aeroMomentByAzimuth = aux.aeroMomentByAzimuth;
                info.gravityMomentByAzimuth = aux.gravityMomentByAzimuth;
                info.residualByAzimuth = aux.residualByAzimuth;
                return;
            end

            J = flap_jacobian(z, viMean, aux.scale);
            if ~all(isfinite(J(:))) || rcond(J.'*J) < 1e-14
                info.exitStatus = 'singular_jacobian';
                return;
            end

            lambda = P.rotor.flapNewtonRegularization;
            dz = -(J.'*J + lambda*eye(3)) \ (J.'*Rn);

            alpha = 1.0;
            accepted = false;
            for trial = 1:P.rotor.flapLineSearchMaxIter
                zCandidate = z + alpha*dz;
                if is_valid_flap_state(zCandidate)
                    [Rc, auxc] = flap_residual(zCandidate, viMean);
                    nCandidate = norm(Rc/auxc.scale);
                    if nCandidate < nR
                        z = zCandidate;
                        accepted = true;
                        break;
                    end
                end
                alpha = alpha * P.rotor.flapNewtonDamping;
            end

            if ~accepted
                info.exitStatus = 'line_search_failed';
                return;
            end
        end

        [R, aux] = flap_residual(z, viMean);
        info.iterations = P.rotor.flapMaxIter;
        info.residual = R;
        info.residualNorm = norm(R/aux.scale);
        info.scale = aux.scale;
        info.exitStatus = 'max_iter';
    end

    function J = flap_jacobian(z, viMean, scale)
        J = zeros(3,3);
        for j = 1:3
            h = P.rotor.flapJacobianStep*max(1, abs(z(j)));
            zp = z;
            zm = z;
            zp(j) = zp(j) + h;
            zm(j) = zm(j) - h;
            Rp = flap_residual(zp, viMean);
            Rm = flap_residual(zm, viMean);
            J(:,j) = (Rp/scale - Rm/scale)/(2*h);
        end
    end

    function tf = is_valid_flap_state(z)
        psiCheck = azimuth_grid();
        betaCheck = z(1) + z(2)*cos(psiCheck) + z(3)*sin(psiCheck);
        tf = all(isfinite(z)) && ...
             max(abs(betaCheck)) < P.rotor.flapDivergenceAngle;
    end

    function [R, aux] = flap_residual(z, viMean)
        loadsLocal = blade_loads(viMean, z);
        psiLocal = loadsLocal.psi;
        beta = loadsLocal.beta;
        betaDDot = loadsLocal.betaDDot;

        gBody = P.env.g * [-sin(thetaBody);
                            sin(phiBody)*cos(thetaBody);
                            cos(phiBody)*cos(thetaBody)];
        gT = dot(gBody, eT);
        gD = dot(gBody, eD);
        gY = dot(gBody, eY);
        gRadial = gD*cos(psiLocal) + gY*sin(psiLocal);

        gravityMoment = P.rotor.Sblade * ...
            (-sin(beta).*gRadial + cos(beta).*gT);

        inertialRestoring = P.rotor.Ib*betaDDot + ...
            P.rotor.Ib*P.rotor.Omega^2*beta;

        residualByAz = inertialRestoring ...
            - loadsLocal.flapMomentByAzimuth ...
            - gravityMoment;

        R = [mean(residualByAz);
             2*mean(residualByAz.*cos(psiLocal));
             2*mean(residualByAz.*sin(psiLocal))];

        scale = max([max(abs(loadsLocal.flapMomentByAzimuth)), ...
            max(abs(gravityMoment)), ...
            P.rotor.Ib*P.rotor.Omega^2*0.05, 1]);

        aux.scale = scale;
        aux.aeroMomentByAzimuth = loadsLocal.flapMomentByAzimuth;
        aux.gravityMomentByAzimuth = gravityMoment;
        aux.residualByAzimuth = residualByAz;
    end

    function loads = blade_loads(viMean, zFlapLocal)
        r0 = P.rotor.rootCut*P.rotor.R;
        rEdges = linspace(r0, P.rotor.R, P.rotor.nRadial + 1);
        rMid = 0.5*(rEdges(1:end-1) + rEdges(2:end));
        dr = diff(rEdges);

        psi = azimuth_grid().';
        beta = zFlapLocal(1) + zFlapLocal(2)*cos(psi) + ...
            zFlapLocal(3)*sin(psi);
        betaDot = rotDir*P.rotor.Omega * ...
            (-zFlapLocal(2)*sin(psi) + zFlapLocal(3)*cos(psi));
        betaDDot = -P.rotor.Omega^2 * ...
            (zFlapLocal(2)*cos(psi) + zFlapLocal(3)*sin(psi));

        etD = -rotDir*sin(psi);
        etY =  rotDir*cos(psi);
        VtanTrans = Vlong*etD + Vlat*etY;
        Vrad = Vlong*cos(psi) + Vlat*sin(psi);

        twist = P.rotor.twistTip*(rMid-r0)/max(P.rotor.R-r0, eps);

        theta1c = theta1cCommand;
        theta1s = -rotDir*rotorCtrl.cyclicLong;
        thetaBlade = rotorCtrl.collective + twist + ...
            theta1c*cos(psi) + theta1s*sin(psi);
        UT = P.rotor.Omega*rMid + VtanTrans;

        % NUAA Eq. (12), first-harmonic non-uniform induced velocity.
        % psi=0 is the current spatial +eD direction for both rotors;
        % rotDir only controls blade motion, not this spatial inflow field.
        viField = viMean .* (1 + cos(psi).*(rMid/P.rotor.R));

        baseUP = Vaxial + viField;
        UP = baseUP - beta.*Vrad - betaDot.*rMid;

        if all(abs(zFlapLocal) < 1e-14)
            maxUPDegenerateError = max(abs(UP(:) - baseUP(:)));
        else
            maxUPDegenerateError = NaN;
        end

        W = hypot(UT, UP);
        phiInflow = atan2(UP, max(abs(UT), 1e-8));

        alphaBlade = thetaBlade - phiInflow;

        CL = P.rotor.CLmax*tanh(P.rotor.liftSlope*alphaBlade/P.rotor.CLmax);
        CD = P.rotor.CD0 + P.rotor.kCD*CL.^2;

        qElem = 0.5*P.env.rho*W.^2;
        dL = qElem*P.rotor.chord.*CL.*dr;
        dD = qElem*P.rotor.chord.*CD.*dr;

        dT = dL.*cos(phiInflow) - dD.*sin(phiInflow);
        dH = dD.*cos(phiInflow) + dL.*sin(phiInflow);
        dQ = dH.*rMid;

        Tsum = sum(dT(:));
        Qsum = sum(dQ(:));
        HvecSum = -[sum(sum(dH.*etD)); sum(sum(dH.*etY))];
        flapMomentByAzimuth = sum(dT.*rMid, 2);

        factor = P.rotor.Nb/P.rotor.nAzimuth;

        loads.T = factor*Tsum;
        loads.Q = factor*Qsum;
        loads.Hlong = factor*HvecSum(1);
        loads.Hlat  = factor*HvecSum(2);
        loads.psi = psi;
        loads.rMid = rMid;
        loads.viField = viField;
        loads.viFieldMin = min(viField(:));
        loads.viFieldMax = max(viField(:));
        loads.viFieldAzimuthMeanError = ...
            max(abs(mean(viField, 1) - viMean));
        loads.inflowModel = 'NUAA_EQ12_FIRST_HARMONIC';
        loads.beta = beta;
        loads.betaDot = betaDot;
        loads.betaDDot = betaDDot;
        loads.flapMomentByAzimuth = flapMomentByAzimuth;
        loads.maxUPDegenerateError = maxUPDegenerateError;
        loads.minUT = min(UT(:));
        loads.maxUT = max(UT(:));
        loads.maxAbsAlphaBlade = max(abs(alphaBlade(:)));
    end

    function psi = azimuth_grid()
        psi = (0:P.rotor.nAzimuth-1)*(2*pi/P.rotor.nAzimuth);
    end
end
