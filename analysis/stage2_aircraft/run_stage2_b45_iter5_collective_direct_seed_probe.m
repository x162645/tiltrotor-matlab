function results=run_stage2_b45_iter5_collective_direct_seed_probe(outputRoot)
%RUN_STAGE2_B45_ITER5_COLLECTIVE_DIRECT_SEED_PROBE
% Fast diagnostic-only probe at the archived post-iter8 terminal point.
% Uses the archived converged left/right zFlap states only as nonlinear solver
% initial guesses. No equations, physical parameters, tolerances, limits,
% iteration counts, trim bounds, or trim/control DOFs are changed.
if nargin<1||isempty(outputRoot), outputRoot=fullfile(pwd,'results','stage2_b45_iter5_collective_direct_seed_probe'); end
if ~exist(outputRoot,'dir'), mkdir(outputRoot); end
P=stage2_matched_rotor_parameters(); d2r=pi/180;
condition=struct('name','B45_V035','V',35,'betaM',45*d2r,'gamma',0,'mode','conversion_longitudinal');
definition=make_trim_definition(condition.mode,condition,P); scale=definition.variableScale(:);
z=[0.369511159961705;0.609760820093650;1.64209994397615];
expected=[-0.110799717573510;-0.402867889354836;0.0734445695198193];
P0=P;
P0.stage2Numerics.flapInitialLeft=[0.01779756670637974;0.5068067239388294;-0.01925343328660319];
P0.stage2Numerics.flapInitialRight=[0.01779756670637973;0.5068067239388293;0.01925343328660322];
point=stage2_evaluate_trim_point('M1_EVIDENCE_V1_PROPAGATION',condition,definition,z,P0);
assert(point.finiteReal&&point.physicalConverged&&point.physicalBranchSupported&&norm(point.residual-expected)<=5e-9, ...
 'run_stage2_b45_iter5_collective_direct_seed_probe:SeedDrift','Archived direct zFlap seeds failed to reproduce terminal point.');
fractions=[1e-4 7.5e-5 5e-5 2.5e-5 1e-5 5e-6 2.5e-6 1e-6];
substeps=[1 2 4 8 16]; rows=repmat(empty_row(),numel(fractions)*2,1); n=0;
for fi=1:numel(fractions)
 f=fractions(fi);
 for si=1:2
  sgn=2*si-3; n=n+1; r=empty_row(); r.stepFraction=f; r.sign=sgn;
  zt=z; zt(2)=zt(2)+sgn*f*scale(2); r.targetCollective=zt(2);
  for ni=1:numel(substeps)
   ns=substeps(ni); r.maxSubstepsTried=ns;
   try
    pt=advance_fixed(point,z,zt,ns);
    r.supported=true; r.firstSuccessfulSubsteps=ns; r.status=pt.physicalStatus;
    r.residualNorm=norm(pt.residual); r.residual1=pt.residual(1); r.residual2=pt.residual(2); r.residual3=pt.residual(3);
    break;
   catch ME
    r.status=['ERROR:' ME.identifier];
   end
  end
  rows(n)=r;
  fprintf('B45_I5_DIRECT|f=%.7g|sign=%+d|supported=%d|firstSubsteps=%g|maxTried=%g|status=%s|raw=%.12e\n', ...
   f,sgn,r.supported,r.firstSuccessfulSubsteps,r.maxSubstepsTried,r.status,r.residualNorm);
 end
end
T=struct2table(rows(1:n)); writetable(T,fullfile(outputRoot,'STAGE2_B45_ITER5_COLLECTIVE_DIRECT_SEED_PROBE.csv'));
S=struct2table(struct('caseName',condition.name,'baseResidualNorm',norm(point.residual), ...
 'minimumTestedFraction',min(fractions),'maximumTestedFraction',max(fractions), ...
 'smallestMinusSupported',min_supported(T,-1),'smallestPlusSupported',min_supported(T,1), ...
 'bothSidesSupportedAtAnyCommonFraction',common_supported(T)));
writetable(S,fullfile(outputRoot,'STAGE2_B45_ITER5_COLLECTIVE_DIRECT_SEED_SUMMARY.csv'));
results=struct('summary',S,'probe',T,'basePoint',point,'baseZ',z,'claimBoundary', ...
 'ARCHIVED_ZFLAP_INITIAL_GUESS_PROBE_ONLY_NO_PHYSICS_OR_SOLVER_SETTING_CHANGE');
save(fullfile(outputRoot,'STAGE2_B45_ITER5_COLLECTIVE_DIRECT_SEED_PROBE.mat'),'results'); disp(S);
 function pt=advance_fixed(startPoint,zStart,zTarget,nSteps)
  l=startPoint.eomOut.components.rotorLeft.zFlap(:); rr=startPoint.eomOut.components.rotorRight.zFlap(:); pt=startPoint;
  for kk=1:nSteps
   zk=zStart+(kk/nSteps)*(zTarget-zStart); Pk=P; Pk.stage2Numerics.flapInitialLeft=l; Pk.stage2Numerics.flapInitialRight=rr;
   pt=stage2_evaluate_trim_point('M1_EVIDENCE_V1_PROPAGATION',condition,definition,zk,Pk);
   if ~(pt.finiteReal&&pt.physicalConverged&&pt.physicalBranchSupported)
    error('run_stage2_b45_iter5_collective_direct_seed_probe:UnsupportedSubstep','Unsupported substep %d/%d: %s',kk,nSteps,pt.physicalStatus);
   end
   l=pt.eomOut.components.rotorLeft.zFlap(:); rr=pt.eomOut.components.rotorRight.zFlap(:);
  end
 end
end
function v=min_supported(T,sgn), x=T.stepFraction(T.supported&T.sign==sgn); if isempty(x), v=NaN; else, v=min(x); end, end
function tf=common_supported(T)
f=unique(T.stepFraction); tf=false; for k=1:numel(f), tf=tf||(any(T.supported&T.sign<0&T.stepFraction==f(k))&&any(T.supported&T.sign>0&T.stepFraction==f(k))); end
end
function r=empty_row()
r=struct('stepFraction',NaN,'sign',NaN,'targetCollective',NaN,'supported',false,'firstSuccessfulSubsteps',NaN, ...
 'maxSubstepsTried',NaN,'status','','residualNorm',NaN,'residual1',NaN,'residual2',NaN,'residual3',NaN);
end
