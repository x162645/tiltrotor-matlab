function results=run_stage2_b45_microfd_expanding_trust_trim_audit(outputRoot)
%RUN_STAGE2_B45_MICROFD_EXPANDING_TRUST_TRIM_AUDIT
% Evidence-based continuation of the B45 M1 trim investigation.
% Prior accepted steps had alpha=1 and actual/predicted reduction ratios
% 0.99997, 0.99995, 0.99992, 0.99989 while the trust radius grew to 0.02.
% This audit therefore permits the standard trust-region expansion rule to
% continue beyond that previous analysis-only cap. Model equations, physical
% parameters, nonlinear-solver tolerances/iteration limits, trim bounds and
% trim/control DOFs are unchanged.
if nargin<1||isempty(outputRoot), outputRoot=fullfile(pwd,'results','stage2_b45_microfd_expanding_trust_trim_audit'); end
if ~exist(outputRoot,'dir'), mkdir(outputRoot); end
P=stage2_matched_rotor_parameters(); d2r=pi/180;
condition=struct('name','B45_V035','V',35,'betaM',45*d2r,'gamma',0,'mode','conversion_longitudinal');
definition=make_trim_definition(condition.mode,condition,P); scale=definition.variableScale(:);
residualScale=ones(numel(definition.residualNames),1);
for i=1:numel(definition.residualNames), if any(strcmp(definition.residualNames{i},{'udot','vdot','wdot'})), residualScale(i)=P.env.g; end, end
z=[0.369511159961705;0.609760820093650;1.64209994397615];
expected=[-0.110799717573510;-0.402867889354836;0.0734445695198193];
P0=P; P0.stage2Numerics.flapInitialLeft=[0.01779756670637974;0.5068067239388294;-0.01925343328660319];
P0.stage2Numerics.flapInitialRight=[0.01779756670637973;0.5068067239388293;0.01925343328660322];
point=stage2_evaluate_trim_point('M1_EVIDENCE_V1_PROPAGATION',condition,definition,z,P0);
assert(point.finiteReal&&point.physicalConverged&&point.physicalBranchSupported&&norm(point.residual-expected)<=5e-9, ...
 'run_stage2_b45_microfd_expanding_trust_trim_audit:SeedDrift','Archived terminal state failed reproduction.');

fdFractions=[1e-4 7.5e-5 5e-5 2.5e-5 1e-5 5e-6 2.5e-6 1e-6];
% First iteration verifies the known 1e-4 failure then selects the first
% supported smaller scale. Later iterations reuse that supported scale and
% shrink only if necessary, avoiding repeated known-unsupported probes.
fdIndex=1;
lineAlphas=[1 0.5 0.25 0.125 0.0625]; trialMaxSubsteps=[5e-4 2.5e-4 1.25e-4 7.5e-5];
maxIter=25; trustRadius=2e-2; trustMin=1.25e-4; trustMax=1.6e-1;
iterRows=repmat(empty_iter(),maxIter,1); attemptRows=repmat(empty_attempt(),maxIter*numel(fdFractions),1);
nDone=0; attemptCount=0; stopReason='MAX_ITER';
for iter=1:maxIter
 nDone=iter; phi0=obj(point); raw0=norm(point.residual); rs=point.residual(:)./residualScale;
 selected=false; Jscaled=NaN(3); sv=[NaN;NaN;NaN]; rankJ=0; condJ=Inf; selectedF=NaN;
 % On the first iteration start at 1e-4. Thereafter start from the last
 % supported index and only move toward smaller scales if support is lost.
 for fi=fdIndex:numel(fdFractions)
  f=fdFractions(fi); attemptCount=attemptCount+1;
  [J,support,status]=centered(point,z,f); Js=diag(1./residualScale)*J*diag(scale);
  finiteJ=isreal(Js)&&all(isfinite(Js(:)))&&all(support(:));
  if finiteJ
   [~,S,~]=svd(Js); st=diag(S); tol=max(size(Js))*eps(max(st)); rt=sum(st>tol);
   if st(end)<=tol, ct=Inf; else, ct=st(1)/st(end); end
  else, st=[NaN;NaN;NaN]; rt=0; ct=Inf; end
  ar=empty_attempt(); ar.iteration=iter; ar.stepFraction=f; ar.supportedNeighborCount=sum(support(:)); ar.allSixSupported=all(support(:));
  ar.rankScaled=rt; ar.conditionScaled=ct; ar.s1=st(1); ar.s2=st(2); ar.s3=st(3);
  ar.thetaMinusStatus=status{1,1}; ar.thetaPlusStatus=status{1,2}; ar.collectiveMinusStatus=status{2,1}; ar.collectivePlusStatus=status{2,2};
  ar.pitchMinusStatus=status{3,1}; ar.pitchPlusStatus=status{3,2}; attemptRows(attemptCount)=ar;
  if finiteJ&&rt==3, selected=true; Jscaled=Js; sv=st; rankJ=rt; condJ=ct; selectedF=f; fdIndex=fi; break; end
 end
 row=empty_iter(); row.iteration=iter; row.z1=z(1); row.z2=z(2); row.z3=z(3); row.residualNormRaw=raw0; row.objectiveScaled=phi0;
 row.residual1=point.residual(1); row.residual2=point.residual(2); row.residual3=point.residual(3); row.selectedFdFraction=selectedF;
 row.rankScaled=rankJ; row.conditionScaled=condJ; row.s1=sv(1); row.s2=sv(2); row.s3=sv(3); row.trustRadius=trustRadius;
 if raw0<P.trim.residualTolerance, row.stopTag='RESIDUAL_TOLERANCE_REACHED'; iterRows(iter)=row; stopReason=row.stopTag; break; end
 if ~selected, row.stopTag='NO_SUPPORTED_FULL_RANK_CENTERED_JACOBIAN'; iterRows(iter)=row; stopReason=row.stopTag; break; end
 etaGN=-pinv(Jscaled)*rs; eta=etaGN; if max(abs(eta))>trustRadius, eta=eta*(trustRadius/max(abs(eta))); end
 row.gnStepInf=max(abs(etaGN)); row.appliedStepInf=max(abs(eta)); dz=scale.*eta;
 bestPhi=phi0; bestRaw=raw0; bestPoint=point; bestZ=z; bestAlpha=0; bestRatio=NaN; bestUsed=NaN;
 for ai=1:numel(lineAlphas)
  aa=lineAlphas(ai); zt=z+aa*dz; if any(zt<definition.bounds(:,1)|zt>definition.bounds(:,2)), continue; end
  [ok,pt,used]=try_advance(point,z,zt); if ~ok, continue; end
  ph=obj(pt); if ph<bestPhi
   pred=rs+Jscaled*(aa*eta); predPhi=sum(pred.^2)+pt.penalty; den=phi0-predPhi; if den>eps, rat=(phi0-ph)/den; else, rat=NaN; end
   bestPhi=ph; bestRaw=norm(pt.residual); bestPoint=pt; bestZ=zt; bestAlpha=aa; bestRatio=rat; bestUsed=used;
  end
 end
 row.bestAlpha=bestAlpha; row.bestTrialResidualNormRaw=bestRaw; row.bestTrialObjectiveScaled=bestPhi; row.actualToPredictedReductionRatio=bestRatio; row.acceptedContinuationMaxSubstep=bestUsed;
 if bestAlpha<=0
  trustRadius=0.5*trustRadius; row.trustRadiusNext=trustRadius;
  if trustRadius<trustMin, row.stopTag='NO_OBJECTIVE_DECREASING_STEP_AT_MIN_TRUST_RADIUS'; iterRows(iter)=row; stopReason=row.stopTag; break; end
  row.stopTag='REJECT_AND_SHRINK_TRUST_REGION'; iterRows(iter)=row;
  fprintf('B45_XTRUST|iter=%d|raw=%.12e|fd=%.7g|trust_next=%.7g|stop=%s\n',iter,raw0,selectedF,trustRadius,row.stopTag); continue;
 end
 if isfinite(bestRatio)&&bestRatio<0.25, trustRadius=max(trustMin,0.5*trustRadius);
 elseif isfinite(bestRatio)&&bestRatio>0.75&&bestAlpha==1&&row.appliedStepInf>=0.9*row.trustRadius, trustRadius=min(trustMax,1.5*trustRadius); end
 row.trustRadiusNext=trustRadius; row.stopTag='ACCEPT'; iterRows(iter)=row;
 fprintf('B45_XTRUST|iter=%d|raw=%.12e->%.12e|fd=%.7g|cond=%.6e|trust=%.7g->%.7g|alpha=%.4g|ratio=%.6g|maxsub=%.7g\n', ...
  iter,raw0,bestRaw,selectedF,condJ,row.trustRadius,trustRadius,bestAlpha,bestRatio,bestUsed);
 z=bestZ; point=bestPoint;
end
iterations=struct2table(iterRows(1:nDone)); attempts=struct2table(attemptRows(1:attemptCount));
span=definition.bounds(:,2)-definition.bounds(:,1); margin=min(z-definition.bounds(:,1),definition.bounds(:,2)-z)./span; atLimit=any(margin<=1e-8);
credible=point.finiteReal&&point.physicalConverged&&point.physicalBranchSupported&&norm(point.residual)<P.trim.residualTolerance&&~atLimit;
s=struct('caseName',condition.name,'startResidualNorm',norm(expected),'finalResidualNorm',norm(point.residual), ...
 'finalObjectiveScaled',obj(point),'finalZ1',z(1),'finalZ2',z(2),'finalZ3',z(3),'finalResidual1',point.residual(1), ...
 'finalResidual2',point.residual(2),'finalResidual3',point.residual(3),'trimResidualTolerance',P.trim.residualTolerance, ...
 'physicalConverged',point.physicalConverged,'physicalBranchSupported',point.physicalBranchSupported,'atLimit',atLimit, ...
 'minimumBoundMargin',min(margin),'credible',credible,'iterations',nDone,'stopReason',stopReason,'finalTrustRadius',trustRadius, ...
 'minimumSelectedFdFraction',minsel(iterations),'maximumSelectedFdFraction',maxsel(iterations)); summary=struct2table(s);
writetable(summary,fullfile(outputRoot,'STAGE2_B45_MICROFD_EXPANDING_TRUST_SUMMARY.csv')); writetable(iterations,fullfile(outputRoot,'STAGE2_B45_MICROFD_EXPANDING_TRUST_ITERATIONS.csv'));
writetable(attempts,fullfile(outputRoot,'STAGE2_B45_MICROFD_EXPANDING_TRUST_JACOBIAN_ATTEMPTS.csv'));
results=struct('summary',summary,'iterations',iterations,'jacobianAttempts',attempts,'finalPoint',point,'finalZ',z, ...
 'claimBoundary','EVIDENCE_BASED_TRUST_EXPANSION_AND_MICRO_FD_BRANCH_TRACKING_ONLY_NO_PHYSICS_PARAMETER_TOLERANCE_BOUND_OR_DOF_CHANGE');
save(fullfile(outputRoot,'STAGE2_B45_MICROFD_EXPANDING_TRUST_AUDIT.mat'),'results'); disp(summary); disp(iterations);
fprintf('B45_XTRUST_FINAL|start=%.12e|final=%.12e|tol=%.12e|credible=%d|iters=%d|fdmin=%.7g|minmargin=%.7g|stop=%s\n', ...
 s.startResidualNorm,s.finalResidualNorm,s.trimResidualTolerance,s.credible,s.iterations,s.minimumSelectedFdFraction,s.minimumBoundMargin,s.stopReason);
 function v=obj(pt), rr=pt.residual(:)./residualScale; v=sum(rr.^2)+pt.penalty; end
 function [J,support,status]=centered(bp,zb,f)
  J=NaN(3); support=false(3,2); status=repmat({'NOT_RUN'},3,2); h=f*scale;
  for jj=1:3
   rp=NaN(3,1); rm=NaN(3,1);
   for si=1:2
    sg=2*si-3; zt=zb; zt(jj)=zt(jj)+sg*h(jj);
    try, pt=advance_fixed(bp,zb,zt,2); support(jj,si)=pt.finiteReal&&pt.physicalConverged&&pt.physicalBranchSupported; status{jj,si}=pt.physicalStatus;
     if support(jj,si), if si==1, rm=pt.residual(:); else, rp=pt.residual(:); end, end
    catch ME, status{jj,si}=['ERROR:' ME.identifier]; end
   end
   if all(support(jj,:)), J(:,jj)=(rp-rm)/(2*h(jj)); end
  end
 end
 function [ok,pt,used]=try_advance(bp,zb,zt)
  ok=false; pt=bp; used=NaN; dist=max(abs((zt-zb)./scale));
  for ci=1:numel(trialMaxSubsteps)
   mf=trialMaxSubsteps(ci); ns=max(1,ceil(dist/mf));
   try, cand=advance_fixed(bp,zb,zt,ns); ok=true; pt=cand; used=mf; return; catch, end
  end
 end
 function pt=advance_fixed(bp,zb,zt,ns)
  l=bp.eomOut.components.rotorLeft.zFlap(:); r=bp.eomOut.components.rotorRight.zFlap(:); pt=bp;
  for kk=1:ns
   zk=zb+(kk/ns)*(zt-zb); Pk=P; Pk.stage2Numerics.flapInitialLeft=l; Pk.stage2Numerics.flapInitialRight=r;
   pt=stage2_evaluate_trim_point('M1_EVIDENCE_V1_PROPAGATION',condition,definition,zk,Pk);
   if ~(pt.finiteReal&&pt.physicalConverged&&pt.physicalBranchSupported), error('run_stage2_b45_microfd_expanding_trust_trim_audit:Unsupported','%s',pt.physicalStatus); end
   l=pt.eomOut.components.rotorLeft.zFlap(:); r=pt.eomOut.components.rotorRight.zFlap(:);
  end
 end
end
function f=minsel(T), v=T.selectedFdFraction(isfinite(T.selectedFdFraction)); if isempty(v),f=NaN;else,f=min(v);end,end
function f=maxsel(T), v=T.selectedFdFraction(isfinite(T.selectedFdFraction)); if isempty(v),f=NaN;else,f=max(v);end,end
function r=empty_iter(), r=struct('iteration',NaN,'z1',NaN,'z2',NaN,'z3',NaN,'residual1',NaN,'residual2',NaN,'residual3',NaN,'residualNormRaw',NaN,'objectiveScaled',NaN,'selectedFdFraction',NaN,'rankScaled',NaN,'conditionScaled',NaN,'s1',NaN,'s2',NaN,'s3',NaN,'trustRadius',NaN,'gnStepInf',NaN,'appliedStepInf',NaN,'bestAlpha',NaN,'bestTrialResidualNormRaw',NaN,'bestTrialObjectiveScaled',NaN,'actualToPredictedReductionRatio',NaN,'acceptedContinuationMaxSubstep',NaN,'trustRadiusNext',NaN,'stopTag',''); end
function r=empty_attempt(), r=struct('iteration',NaN,'stepFraction',NaN,'supportedNeighborCount',0,'allSixSupported',false,'rankScaled',NaN,'conditionScaled',NaN,'s1',NaN,'s2',NaN,'s3',NaN,'thetaMinusStatus','','thetaPlusStatus','','collectiveMinusStatus','','collectivePlusStatus','','pitchMinusStatus','','pitchPlusStatus',''); end
