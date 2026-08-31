function results=run_stage2_b45_recursive_continuation_trim_audit(outputRoot)
%RUN_STAGE2_B45_RECURSIVE_CONTINUATION_TRIM_AUDIT
% Fast diagnostic trim continuation for B45. A target point is first tried
% directly using the current converged left/right zFlap states as nonlinear
% solver initial guesses. Only failed path segments are recursively bisected.
% No aircraft/rotor equations, physical parameters, nonlinear-solver
% tolerances/iteration limits, trim bounds, or trim/control DOFs are changed.
if nargin<1||isempty(outputRoot),outputRoot=fullfile(pwd,'results','stage2_b45_recursive_continuation_trim_audit');end
if ~exist(outputRoot,'dir'),mkdir(outputRoot);end
P=stage2_matched_rotor_parameters(); d2r=pi/180;
c=struct('name','B45_V035','V',35,'betaM',45*d2r,'gamma',0,'mode','conversion_longitudinal');
d=make_trim_definition(c.mode,c,P); sc=d.variableScale(:);
rscl=ones(numel(d.residualNames),1); for i=1:numel(d.residualNames),if any(strcmp(d.residualNames{i},{'udot','vdot','wdot'})),rscl(i)=P.env.g;end,end
z=[0.369511159961705;0.609760820093650;1.64209994397615];
rex=[-0.110799717573510;-0.402867889354836;0.0734445695198193];
P0=P;P0.stage2Numerics.flapInitialLeft=[0.01779756670637974;0.5068067239388294;-0.01925343328660319];
P0.stage2Numerics.flapInitialRight=[0.01779756670637973;0.5068067239388293;0.01925343328660322];
p=stage2_evaluate_trim_point('M1_EVIDENCE_V1_PROPAGATION',c,d,z,P0);
assert(p.finiteReal&&p.physicalConverged&&p.physicalBranchSupported&&norm(p.residual-rex)<=5e-9,'B45Recursive:SeedDrift','Archived terminal state failed reproduction.');
fd=[7.5e-5 5e-5 2.5e-5 1e-5 5e-6 2.5e-6 1e-6]; fdIdx=1;
trust=2e-2; trustMin=1.25e-4; trustMax=1.6e-1; maxIter=20; maxDepth=14;
rows=repmat(emptyrow(),maxIter,1); n=0; stop='MAX_ITER'; totalEval=0;
for it=1:maxIter
 n=it; phi0=obj(p); raw0=norm(p.residual); rscaled=p.residual(:)./rscl;
 selected=false; Jn=NaN(3); fsel=NaN; condJ=Inf; sv=[NaN;NaN;NaN];
 for fi=fdIdx:numel(fd)
  [J,sup,ev]=jac(p,z,fd(fi)); totalEval=totalEval+ev; Js=diag(1./rscl)*J*diag(sc);
  if all(sup(:))&&all(isfinite(Js(:)))&&isreal(Js)
   [~,S,~]=svd(Js); st=diag(S); tol=max(size(Js))*eps(max(st)); rk=sum(st>tol);
   if rk==3
    selected=true; Jn=Js; fsel=fd(fi); sv=st; condJ=st(1)/st(3); fdIdx=fi; break;
   end
  end
 end
 row=emptyrow();row.iteration=it;row.z1=z(1);row.z2=z(2);row.z3=z(3);row.residualNormRaw=raw0;row.objectiveScaled=phi0;row.fdFraction=fsel;row.conditionScaled=condJ;row.s1=sv(1);row.s2=sv(2);row.s3=sv(3);row.trustRadius=trust;
 if raw0<P.trim.residualTolerance,row.stopTag='RESIDUAL_TOLERANCE_REACHED';rows(it)=row;stop=row.stopTag;break;end
 if ~selected,row.stopTag='NO_SUPPORTED_FULL_RANK_MICRO_JACOBIAN';rows(it)=row;stop=row.stopTag;break;end
 eta=-pinv(Jn)*rscaled; row.gnStepInf=max(abs(eta)); if max(abs(eta))>trust,eta=eta*(trust/max(abs(eta)));end;row.appliedStepInf=max(abs(eta)); dz=sc.*eta;
 alphas=[1 .5 .25 .125 .0625];accepted=false;bestP=p;bestZ=z;bestPhi=phi0;bestRaw=raw0;bestA=0;bestRatio=NaN;bestDepth=NaN;bestE=0;
 for ai=1:numel(alphas)
  a=alphas(ai);zt=z+a*dz;if any(zt<d.bounds(:,1)|zt>d.bounds(:,2)),continue;end
  [ok,pt,depthUsed,ev]=advance_recursive(p,z,zt,0); totalEval=totalEval+ev;
  if ~ok,continue;end
  ph=obj(pt); pred=rscaled+Jn*(a*eta); predPhi=sum(pred.^2)+pt.penalty; den=phi0-predPhi;if den>eps,rat=(phi0-ph)/den;else,rat=NaN;end
  if ph<bestPhi
   bestP=pt;bestZ=zt;bestPhi=ph;bestRaw=norm(pt.residual);bestA=a;bestRatio=rat;bestDepth=depthUsed;bestE=ev;accepted=true;
   % Prior evidence gave ratios ~0.9999. If the full step remains accurately
   % predicted, accept immediately; otherwise fall through to backtracking.
   if ai==1&&isfinite(rat)&&rat>0.75,break;end
  end
 end
 row.bestAlpha=bestA;row.bestTrialRaw=bestRaw;row.bestTrialObjective=bestPhi;row.reductionRatio=bestRatio;row.recursionDepth=bestDepth;row.acceptedEvalCount=bestE;
 if ~accepted
  trust=0.5*trust;row.trustRadiusNext=trust;
  if trust<trustMin,row.stopTag='NO_DECREASING_STEP_AT_MIN_TRUST';rows(it)=row;stop=row.stopTag;break;end
  row.stopTag='REJECT_SHRINK';rows(it)=row;fprintf('B45_RECUR|it=%d|raw=%.12e|fd=%.7g|trust=%.7g|stop=%s\n',it,raw0,fsel,trust,row.stopTag);continue;
 end
 if isfinite(bestRatio)&&bestRatio<.25,trust=max(trustMin,.5*trust);elseif isfinite(bestRatio)&&bestRatio>.75&&bestA==1&&row.appliedStepInf>=.9*row.trustRadius,trust=min(trustMax,1.5*trust);end
 row.trustRadiusNext=trust;row.stopTag='ACCEPT';rows(it)=row;
 fprintf('B45_RECUR|it=%d|raw=%.12e->%.12e|phi=%.12e->%.12e|fd=%.7g|cond=%.6e|trust=%.7g->%.7g|a=%.4g|ratio=%.6g|depth=%g|evals=%d\n',it,raw0,bestRaw,phi0,bestPhi,fsel,condJ,row.trustRadius,trust,bestA,bestRatio,bestDepth,totalEval);
 z=bestZ;p=bestP;
end
T=struct2table(rows(1:n));span=d.bounds(:,2)-d.bounds(:,1);margin=min(z-d.bounds(:,1),d.bounds(:,2)-z)./span;atLimit=any(margin<=1e-8);
cred=p.finiteReal&&p.physicalConverged&&p.physicalBranchSupported&&norm(p.residual)<P.trim.residualTolerance&&~atLimit;
s=struct('caseName',c.name,'startResidualNorm',norm(rex),'finalResidualNorm',norm(p.residual),'finalObjectiveScaled',obj(p),'finalZ1',z(1),'finalZ2',z(2),'finalZ3',z(3),'finalResidual1',p.residual(1),'finalResidual2',p.residual(2),'finalResidual3',p.residual(3),'trimResidualTolerance',P.trim.residualTolerance,'physicalConverged',p.physicalConverged,'physicalBranchSupported',p.physicalBranchSupported,'atLimit',atLimit,'minimumBoundMargin',min(margin),'credible',cred,'iterations',n,'stopReason',stop,'finalTrustRadius',trust,'totalModelEvaluations',totalEval,'minimumSelectedFdFraction',minfd(T));S=struct2table(s);
writetable(S,fullfile(outputRoot,'STAGE2_B45_RECURSIVE_CONTINUATION_TRIM_SUMMARY.csv'));writetable(T,fullfile(outputRoot,'STAGE2_B45_RECURSIVE_CONTINUATION_TRIM_ITERATIONS.csv'));results=struct('summary',S,'iterations',T,'finalPoint',p,'finalZ',z,'claimBoundary','RECURSIVE_BRANCH_CONTINUATION_AND_MICRO_FD_ONLY_NO_PHYSICS_PARAMETER_TOLERANCE_BOUND_OR_DOF_CHANGE');save(fullfile(outputRoot,'STAGE2_B45_RECURSIVE_CONTINUATION_TRIM_AUDIT.mat'),'results');disp(S);disp(T);fprintf('B45_RECUR_FINAL|start=%.12e|final=%.12e|tol=%.12e|credible=%d|iters=%d|minfd=%.7g|minmargin=%.7g|evals=%d|stop=%s\n',s.startResidualNorm,s.finalResidualNorm,s.trimResidualTolerance,s.credible,s.iterations,s.minimumSelectedFdFraction,s.minimumBoundMargin,s.totalModelEvaluations,s.stopReason);
 function v=obj(pt),q=pt.residual(:)./rscl;v=sum(q.^2)+pt.penalty;end
 function [J,sup,ev]=jac(bp,zb,f)
  J=NaN(3);sup=false(3,2);ev=0;h=f*sc;
  for jj=1:3
   rr=NaN(3,2);
   for si=1:2
    sg=2*si-3;zt=zb;zt(jj)=zt(jj)+sg*h(jj);[ok,pt,~,ee]=advance_recursive(bp,zb,zt,0);ev=ev+ee;if ok,sup(jj,si)=true;rr(:,si)=pt.residual(:);end
   end
   if all(sup(jj,:)),J(:,jj)=(rr(:,2)-rr(:,1))/(2*h(jj));end
  end
 end
 function [ok,pt,maxD,ev]=advance_recursive(bp,za,zb,depth)
  ev=1;maxD=depth;pt=bp;Pk=P;Pk.stage2Numerics.flapInitialLeft=bp.eomOut.components.rotorLeft.zFlap(:);Pk.stage2Numerics.flapInitialRight=bp.eomOut.components.rotorRight.zFlap(:);
  try
   q=stage2_evaluate_trim_point('M1_EVIDENCE_V1_PROPAGATION',c,d,zb,Pk);
   if q.finiteReal&&q.physicalConverged&&q.physicalBranchSupported,ok=true;pt=q;return;end
  catch
  end
  if depth>=maxDepth,ok=false;return;end
  zm=.5*(za+zb);[ok1,pm,d1,e1]=advance_recursive(bp,za,zm,depth+1);ev=ev+e1;maxD=max(maxD,d1);if ~ok1,ok=false;return;end
  [ok2,pb,d2,e2]=advance_recursive(pm,zm,zb,depth+1);ev=ev+e2;maxD=max(maxD,d2);ok=ok2;if ok2,pt=pb;end
 end
end
function f=minfd(T),v=T.fdFraction(isfinite(T.fdFraction));if isempty(v),f=NaN;else,f=min(v);end,end
function r=emptyrow(),r=struct('iteration',NaN,'z1',NaN,'z2',NaN,'z3',NaN,'residualNormRaw',NaN,'objectiveScaled',NaN,'fdFraction',NaN,'conditionScaled',NaN,'s1',NaN,'s2',NaN,'s3',NaN,'trustRadius',NaN,'gnStepInf',NaN,'appliedStepInf',NaN,'bestAlpha',NaN,'bestTrialRaw',NaN,'bestTrialObjective',NaN,'reductionRatio',NaN,'recursionDepth',NaN,'acceptedEvalCount',NaN,'trustRadiusNext',NaN,'stopTag','');end
