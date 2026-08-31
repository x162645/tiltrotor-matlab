function results=run_stage2_b45_adaptive_path_trim_extension_audit(outputRoot)
%RUN_STAGE2_B45_ADAPTIVE_PATH_TRIM_EXTENSION_AUDIT
% Independent second continuation segment from the terminal point returned by
% run_stage2_b45_adaptive_path_trim_audit. The original 20-iteration segment
% is left unchanged. This extension carries only the converged trim point,
% left/right flap states, and trust radius into a second 20-iteration block.
% No model equations, physical parameters, flap solver tolerances/iteration
% limits, trim bounds, or trim/control DOFs are changed.
if nargin<1||isempty(outputRoot),outputRoot=fullfile(pwd,'results','stage2_b45_adaptive_path_trim_extension_audit');end
if ~exist(outputRoot,'dir'),mkdir(outputRoot);end
baseDir=fullfile(outputRoot,'base_segment');if ~exist(baseDir,'dir'),mkdir(baseDir);end
base=run_stage2_b45_adaptive_path_trim_audit(baseDir);
P=stage2_matched_rotor_parameters();d2r=pi/180;
c=struct('name','B45_V035','V',35,'betaM',45*d2r,'gamma',0,'mode','conversion_longitudinal');
d=make_trim_definition(c.mode,c,P);sc=d.variableScale(:);
rscl=ones(numel(d.residualNames),1);for i=1:numel(d.residualNames),if any(strcmp(d.residualNames{i},{'udot','vdot','wdot'})),rscl(i)=P.env.g;end,end
z=base.finalZ(:);p=base.finalPoint;
assert(p.finiteReal&&p.physicalConverged&&p.physicalBranchSupported,'B45AdaptivePathExtension:UnsupportedSeed','Base-segment terminal point is not supported.');
fd=[7.5e-5 5e-5 2.5e-5 1e-5 5e-6 2.5e-6 1e-6];fdIdx=1;
trust=base.summary.finalTrustRadius(1);trustMin=1.25e-4;trustMax=1.6e-1;maxIter=20;minPathDt=2^-14;maxPathAttempts=80;
rows=repmat(emptyrow(),maxIter,1);n=0;stop='MAX_ITER';totalEval=0;startRaw=norm(p.residual);
for it=1:maxIter
 n=it;phi0=obj(p);raw0=norm(p.residual);rr=p.residual(:)./rscl;
 selected=false;Jscaled=NaN(3);fsel=NaN;condJ=Inf;sv=[NaN;NaN;NaN];
 for fi=fdIdx:numel(fd)
  [J,sup,ev]=jac(p,z,fd(fi));totalEval=totalEval+ev;Js=diag(1./rscl)*J*diag(sc);
  if all(sup(:))&&all(isfinite(Js(:)))&&isreal(Js)
   [~,S,~]=svd(Js);st=diag(S);tol=max(size(Js))*eps(max(st));rk=sum(st>tol);
   if rk==3,selected=true;Jscaled=Js;fsel=fd(fi);sv=st;condJ=st(1)/st(3);fdIdx=fi;break;end
  end
 end
 row=emptyrow();row.iteration=it;row.z1=z(1);row.z2=z(2);row.z3=z(3);row.residualNormRaw=raw0;row.objectiveScaled=phi0;row.fdFraction=fsel;row.conditionScaled=condJ;row.s1=sv(1);row.s2=sv(2);row.s3=sv(3);row.trustRadius=trust;
 if raw0<P.trim.residualTolerance,row.stopTag='RESIDUAL_TOLERANCE_REACHED';rows(it)=row;stop=row.stopTag;break;end
 if ~selected,row.stopTag='NO_SUPPORTED_FULL_RANK_MICRO_JACOBIAN';rows(it)=row;stop=row.stopTag;break;end
 eta=-pinv(Jscaled)*rr;row.gnStepInf=max(abs(eta));if max(abs(eta))>trust,eta=eta*(trust/max(abs(eta)));end;row.appliedStepInf=max(abs(eta));dz=sc.*eta;
 alphas=[1 .5 .25 .125 .0625];accepted=false;bp=p;bz=z;bphi=phi0;braw=raw0;ba=0;br=NaN;batt=NaN;bev=0;
 for ai=1:numel(alphas)
  a=alphas(ai);zt=z+a*dz;if any(zt<d.bounds(:,1)|zt>d.bounds(:,2)),continue;end
  [ok,pt,att,ev]=advance_path(p,z,zt);totalEval=totalEval+ev;if ~ok,continue;end
  ph=obj(pt);pred=rr+Jscaled*(a*eta);predPhi=sum(pred.^2)+pt.penalty;den=phi0-predPhi;if den>eps,rat=(phi0-ph)/den;else,rat=NaN;end
  if ph<bphi
   accepted=true;bp=pt;bz=zt;bphi=ph;braw=norm(pt.residual);ba=a;br=rat;batt=att;bev=ev;
   if ai==1&&isfinite(rat)&&rat>.75,break;end
  end
 end
 row.bestAlpha=ba;row.bestTrialRaw=braw;row.bestTrialObjective=bphi;row.reductionRatio=br;row.pathAttempts=batt;row.acceptedEvalCount=bev;
 if ~accepted
  trust=.5*trust;row.trustRadiusNext=trust;if trust<trustMin,row.stopTag='NO_DECREASING_STEP_AT_MIN_TRUST';rows(it)=row;stop=row.stopTag;break;end
  row.stopTag='REJECT_SHRINK';rows(it)=row;fprintf('B45_APATH_EXT|it=%d|raw=%.12e|fd=%.7g|trust=%.7g|stop=%s\n',it,raw0,fsel,trust,row.stopTag);continue;
 end
 if isfinite(br)&&br<.25,trust=max(trustMin,.5*trust);elseif isfinite(br)&&br>.75&&ba==1&&row.appliedStepInf>=.9*row.trustRadius,trust=min(trustMax,1.5*trust);end
 row.trustRadiusNext=trust;row.stopTag='ACCEPT';rows(it)=row;
 fprintf('B45_APATH_EXT|it=%d|raw=%.12e->%.12e|phi=%.12e->%.12e|fd=%.7g|cond=%.6e|trust=%.7g->%.7g|a=%.4g|ratio=%.6g|pathAttempts=%g|evals=%d\n',it,raw0,braw,phi0,bphi,fsel,condJ,row.trustRadius,trust,ba,br,batt,totalEval);
 z=bz;p=bp;
end
T=struct2table(rows(1:n));span=d.bounds(:,2)-d.bounds(:,1);margin=min(z-d.bounds(:,1),d.bounds(:,2)-z)./span;atLimit=any(margin<=1e-8);cred=p.finiteReal&&p.physicalConverged&&p.physicalBranchSupported&&norm(p.residual)<P.trim.residualTolerance&&~atLimit;
s=struct('caseName',c.name,'segmentStartResidualNorm',startRaw,'finalResidualNorm',norm(p.residual),'finalObjectiveScaled',obj(p),'finalZ1',z(1),'finalZ2',z(2),'finalZ3',z(3),'finalResidual1',p.residual(1),'finalResidual2',p.residual(2),'finalResidual3',p.residual(3),'trimResidualTolerance',P.trim.residualTolerance,'physicalConverged',p.physicalConverged,'physicalBranchSupported',p.physicalBranchSupported,'atLimit',atLimit,'minimumBoundMargin',min(margin),'credible',cred,'iterations',n,'stopReason',stop,'finalTrustRadius',trust,'totalModelEvaluations',totalEval,'minimumSelectedFdFraction',minfd(T));S=struct2table(s);
writetable(S,fullfile(outputRoot,'STAGE2_B45_ADAPTIVE_PATH_TRIM_EXTENSION_SUMMARY.csv'));writetable(T,fullfile(outputRoot,'STAGE2_B45_ADAPTIVE_PATH_TRIM_EXTENSION_ITERATIONS.csv'));results=struct('base',base,'summary',S,'iterations',T,'finalPoint',p,'finalZ',z,'claimBoundary','SECOND_CONTINUATION_SEGMENT_ONLY_NO_PHYSICS_PARAMETER_TOLERANCE_BOUND_OR_DOF_CHANGE');save(fullfile(outputRoot,'STAGE2_B45_ADAPTIVE_PATH_TRIM_EXTENSION_AUDIT.mat'),'results');disp(S);disp(T);fprintf('B45_APATH_EXT_FINAL|start=%.12e|final=%.12e|tol=%.12e|credible=%d|iters=%d|minfd=%.7g|minmargin=%.7g|evals=%d|stop=%s\n',s.segmentStartResidualNorm,s.finalResidualNorm,s.trimResidualTolerance,s.credible,s.iterations,s.minimumSelectedFdFraction,s.minimumBoundMargin,s.totalModelEvaluations,s.stopReason);
 function v=obj(pt),q=pt.residual(:)./rscl;v=sum(q.^2)+pt.penalty;end
 function [J,sup,ev]=jac(bp,zb,f)
  J=NaN(3);sup=false(3,2);ev=0;h=f*sc;
  for jj=1:3
   vals=NaN(3,2);
   for si=1:2
    sg=2*si-3;zt=zb;zt(jj)=zt(jj)+sg*h(jj);[ok,pt,~,ee]=advance_path(bp,zb,zt);ev=ev+ee;if ok,sup(jj,si)=true;vals(:,si)=pt.residual(:);end
   end
   if all(sup(jj,:)),J(:,jj)=(vals(:,2)-vals(:,1))/(2*h(jj));end
  end
 end
 function [ok,pt,attempts,ev]=advance_path(bp,za,zb)
  t=0;dt=1;pt=bp;attempts=0;ev=0;ok=false;
  while t<1-1e-14&&attempts<maxPathAttempts
   ttry=min(1,t+dt);zt=za+ttry*(zb-za);attempts=attempts+1;ev=ev+1;Pk=P;Pk.stage2Numerics.flapInitialLeft=pt.eomOut.components.rotorLeft.zFlap(:);Pk.stage2Numerics.flapInitialRight=pt.eomOut.components.rotorRight.zFlap(:);good=false;
   try,q=stage2_evaluate_trim_point('M1_EVIDENCE_V1_PROPAGATION',c,d,zt,Pk);good=q.finiteReal&&q.physicalConverged&&q.physicalBranchSupported;catch,good=false;end
   if good
    pt=q;t=ttry;if t>=1-1e-14,ok=true;return;end;dt=min(2*dt,1-t);
   else
    dt=.5*dt;if dt<minPathDt,ok=false;return;end
   end
  end
 end
end
function f=minfd(T),v=T.fdFraction(isfinite(T.fdFraction));if isempty(v),f=NaN;else,f=min(v);end,end
function r=emptyrow(),r=struct('iteration',NaN,'z1',NaN,'z2',NaN,'z3',NaN,'residualNormRaw',NaN,'objectiveScaled',NaN,'fdFraction',NaN,'conditionScaled',NaN,'s1',NaN,'s2',NaN,'s3',NaN,'trustRadius',NaN,'gnStepInf',NaN,'appliedStepInf',NaN,'bestAlpha',NaN,'bestTrialRaw',NaN,'bestTrialObjective',NaN,'reductionRatio',NaN,'pathAttempts',NaN,'acceptedEvalCount',NaN,'trustRadiusNext',NaN,'stopTag','');end
