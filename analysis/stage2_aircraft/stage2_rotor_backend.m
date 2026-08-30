function [Fbody,Mbody,out] = stage2_rotor_backend( ...
        modelIdentity,x,rotorCtrl,betaM,side,cgShift,P)
%STAGE2_ROTOR_BACKEND Explicit analysis-only M0/M1 rotor dispatcher.

switch upper(char(modelIdentity))
    case 'M0_MATCHED_PRODUCTION'
        [Fbody,Mbody,out] = rotor_model_bemt( ...
            x,rotorCtrl,betaM,side,cgShift,P);
        out.stage2ModelIdentity = 'M0_MATCHED_PRODUCTION';
        out.stage2ComputationPath = 'DIRECT_PRODUCTION_ROTOR_MODEL_BEMT';
    case 'M1_EVIDENCE_V1_PROPAGATION'
        [Fbody,Mbody,out] = m1_evidence_v1_forward_rotor( ...
            x,rotorCtrl,betaM,side,cgShift,P);
        out.stage2ModelIdentity = 'M1_EVIDENCE_V1_PROPAGATION';
        out.stage2ComputationPath = ...
            'ANALYSIS_ONLY_FROZEN_EVIDENCE_FORWARD_EXTENSION';
    otherwise
        error('stage2_rotor_backend:UnknownModelIdentity', ...
            'Unknown modelIdentity: %s',char(modelIdentity));
end
end
