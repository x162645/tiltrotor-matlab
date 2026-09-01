function results = run_stage2_accepted_modal_matching_reproduction(outputRoot)
%RUN_STAGE2_ACCEPTED_MODAL_MATCHING_REPRODUCTION
% Reproduce accepted B15/B75 M0->M1 modal matching using base MATLAB R2021a.
%
% Evidence contract:
%   * consume four exact 81-element fine-scale A blocks copied from the
%     accepted direct-linearization artifacts;
%   * no retrim, relinearization, continuation, model or solver changes;
%   * one positive-imaginary representative per complex conjugate pair;
%   * global assignment cost = normalized eigenvalue distance + (1 - MAC);
%   * frozen matching table is used only for ordering/regression validation.

if nargin < 1 || isempty(outputRoot)
    outputRoot = fullfile(pwd,'results','stage2_accepted_modal_matching_reproduction');
end
if ~exist(outputRoot,'dir'), mkdir(outputRoot); end

here=fileparts(mfilename('fullpath'));
E=load_exact_A_blocks(here);
F=readtable(fullfile(here,'evidence','STAGE2_ACCEPTED_MODAL_MATCHING.csv'),'TextType','string');
validate_snapshot(E);

cases=["B15_V020";"B75_V080"];
raw=repmat(empty_modal(),0,1);
costRows=repmat(empty_cost(),0,1);
assignmentRows=repmat(empty_assignment(),0,1);

for c=1:numel(cases)
    cs=cases(c);
    m0=canonical_modes(reconstruct_A(E,cs,"M0_MATCHED_PRODUCTION"));
    m1=canonical_modes(reconstruct_A(E,cs,"M1_EVIDENCE_V1_PROPAGATION"));
    must(numel(m0)==numel(m1),'M0/M1 collapsed mode counts differ.');
    [perm,C]=minimum_assignment(m0,m1);

    for i=1:numel(m0)
        for j=1:numel(m1)
            q=empty_cost(); q.caseName=cs; q.M0canonicalIndex=i; q.M1canonicalIndex=j;
            q.M0modeType=m0(i).modeType; q.M1modeType=m1(j).modeType;
            q.compatibleType=m0(i).modeType==m1(j).modeType; q.selected=perm(i)==j;
            if q.compatibleType
                q.normalizedEigenDistance=eig_distance(m0(i).lambda,m1(j).lambda);
                q.MAC=mode_mac(m0(i).vector,m1(j).vector); q.assignmentCost=C(i,j);
            end
            costRows(end+1,1)=q; %#ok<AGROW>
        end
    end

    for i=1:numel(m0)
        j=perm(i); raw(end+1,1)=modal_row(cs,m0(i),m1(j)); %#ok<AGROW>
        q=empty_assignment(); q.caseName=cs; q.M0canonicalIndex=i; q.M1canonicalIndex=j;
        q.modeType=m0(i).modeType; q.normalizedEigenDistance=eig_distance(m0(i).lambda,m1(j).lambda);
        q.MAC=mode_mac(m0(i).vector,m1(j).vector); q.assignmentCost=C(i,j);
        assignmentRows(end+1,1)=q; %#ok<AGROW>
    end
end

Rraw=struct2table(raw,'AsArray',true);
R=order_like_frozen(Rraw,F);
V=validate_against_frozen(R,F);
C=struct2table(costRows,'AsArray',true);
A=struct2table(assignmentRows,'AsArray',true);
summary=table(height(E),height(R),sum(V.rowPass),max(V.maxNumericAbsError), ...
    'VariableNames',{'matrixElementCount','reproducedModeCount','validatedModeCount','maxNumericAbsError'});

writetable(R,fullfile(outputRoot,'STAGE2_REPRODUCED_MODAL_MATCHING.csv'));
writetable(V,fullfile(outputRoot,'STAGE2_MODAL_MATCHING_VALIDATION.csv'));
writetable(C,fullfile(outputRoot,'STAGE2_MODAL_MATCHING_COST_MATRIX.csv'));
writetable(A,fullfile(outputRoot,'STAGE2_MODAL_MATCHING_ASSIGNMENT.csv'));
writetable(summary,fullfile(outputRoot,'STAGE2_MODAL_MATCHING_REPRODUCTION_SUMMARY.csv'));
metadata=table(["FOUR_EXACT_ACCEPTED_FINE_SCALE_A_BLOCKS"; ...
    "SOURCE_B15_ARTIFACT_9781737622"; ...
    "SOURCE_B75_ARTIFACT_9781761914"; ...
    "NO_RETRIM_NO_RELINEARIZATION_NO_CONTINUATION"; ...
    "POSITIVE_IMAGINARY_REPRESENTATIVE_FOR_COMPLEX_PAIR"; ...
    "NORMALIZED_EIGEN_DISTANCE_ABS_DELTA_OVER_MAX_1_ABS_LAMBDA"; ...
    "COMPLEX_EIGENVECTOR_MAC"; ...
    "ASSIGNMENT_COST_EQUALS_DISTANCE_PLUS_ONE_MINUS_MAC"; ...
    "GLOBAL_MINIMUM_COST_BY_BASE_MATLAB_PERMUTATION_ENUMERATION"; ...
    "FROZEN_TABLE_USED_ONLY_FOR_ORDER_AND_REGRESSION_VALIDATION"; ...
    "WHOLE_AIRCRAFT_PROPAGATION_SENSITIVITY_NOT_XV15_AIRCRAFT_VALIDATION"], ...
    'VariableNames',{'metadataValue'});
writetable(metadata,fullfile(outputRoot,'STAGE2_MODAL_MATCHING_REPRODUCTION_METADATA.csv'));

must(height(E)==324,'Accepted full-A evidence must contain 324 elements.');
must(height(R)==13,'Expected 13 collapsed accepted modes.');
must(all(V.rowPass),'MATLAB reproduction does not match frozen accepted modal table.');
results=struct('reproduced',R,'validation',V,'costMatrix',C,'assignment',A, ...
    'summary',summary,'metadata',metadata, ...
    'claimBoundary','WHOLE_AIRCRAFT_PROPAGATION_SENSITIVITY_NOT_XV15_AIRCRAFT_VALIDATION');
save(fullfile(outputRoot,'STAGE2_ACCEPTED_MODAL_MATCHING_REPRODUCTION.mat'),'results');
disp(summary); disp(V);
end

function E=load_exact_A_blocks(here)
d=fullfile(here,'evidence','full_a');
paths={ ...
    fullfile(d,'STAGE2_ACCEPTED_A_B15_M0_SCALE05.csv'), ...
    fullfile(d,'STAGE2_ACCEPTED_A_B15_M1_SCALE05.csv'), ...
    fullfile(d,'STAGE2_ACCEPTED_A_B75_M0_SCALE05.csv'), ...
    fullfile(d,'STAGE2_ACCEPTED_A_B75_M1_SCALE05.csv')};
parts=cell(4,1);
for k=1:4
    must(exist(paths{k},'file')==2,['Missing accepted A evidence block: ' paths{k}]);
    parts{k}=readtable(paths{k},'TextType','string');
    must(height(parts{k})==81,['Accepted A evidence block must have 81 rows: ' paths{k}]);
end
E=[parts{1};parts{2};parts{3};parts{4}];
end

function validate_snapshot(E)
must(height(E)==324,'Matrix evidence row count is not 324.');
must(all(E.matrixName=="A"),'Matrix evidence contains non-A rows.');
must(all(abs(E.stepScale-0.5)<eps),'Matrix evidence contains non-fine-scale rows.');
cases=["B15_V020";"B75_V080"]; models=["M0_MATCHED_PRODUCTION";"M1_EVIDENCE_V1_PROPAGATION"];
for c=1:2
    for m=1:2
        g=E(E.caseName==cases(c) & E.modelIdentity==models(m),:);
        must(height(g)==81,'A matrix block is incomplete.');
        key=(g.rowIndex-1)*9+g.columnIndex;
        must(numel(unique(key))==81 && min(key)==1 && max(key)==81,'A matrix block has duplicate or missing elements.');
        must(all(isfinite(g.value)),'A matrix block contains non-finite values.');
    end
end
must(all(E.sourceArtifactId(E.caseName=="B15_V020")==9781737622),'B15 artifact provenance mismatch.');
must(all(E.sourceArtifactId(E.caseName=="B75_V080")==9781761914),'B75 artifact provenance mismatch.');
must(all(E.sourceArtifactDigest(E.caseName=="B15_V020")=="sha256:c12863890c26e57a614580df38db7a4a830496ca0592092da002087c7afab57f"),'B15 artifact digest mismatch.');
must(all(E.sourceArtifactDigest(E.caseName=="B75_V080")=="sha256:33d7596ee0111e6dd0b3b4ec754ef3399395cdf8fa3ab801cef23376b98d765c"),'B75 artifact digest mismatch.');
end

function A=reconstruct_A(E,caseName,modelIdentity)
g=E(E.caseName==caseName & E.modelIdentity==modelIdentity,:);
must(height(g)==81,'Cannot reconstruct incomplete A matrix.');
A=NaN(9,9);
for k=1:height(g), A(g.rowIndex(k),g.columnIndex(k))=g.value(k); end
must(all(isfinite(A(:))) && isreal(A),'Reconstructed A matrix is invalid.');
end

function modes=canonical_modes(A)
[V,D]=eig(A); lam=diag(D); tol=1e-10; modes=repmat(empty_mode(),0,1);
for k=1:numel(lam)
    z=lam(k);
    if abs(imag(z))<=tol
        q=empty_mode(); q.lambda=complex(real(z),0); q.vector=V(:,k); q.eigIndex=k;
        if abs(z)<=tol, q.modeType="INTEGRATOR"; else, q.modeType="REAL"; end
        modes(end+1,1)=q; %#ok<AGROW>
    elseif imag(z)>tol
        q=empty_mode(); q.lambda=z; q.vector=V(:,k); q.eigIndex=k; q.modeType="COMPLEX_PAIR";
        modes(end+1,1)=q; %#ok<AGROW>
    end
end
must(sum([modes.modeType]=="INTEGRATOR")==1,'Expected exactly one kinematic integrator.');
end

function [bestPerm,C]=minimum_assignment(m0,m1)
n=numel(m0); must(n==numel(m1),'Assignment dimensions differ.'); C=Inf(n,n);
for i=1:n
    for j=1:n
        if m0(i).modeType==m1(j).modeType
            C(i,j)=eig_distance(m0(i).lambda,m1(j).lambda)+(1-mode_mac(m0(i).vector,m1(j).vector));
        end
    end
end
P=perms(1:n); bestCost=Inf; bestPerm=[];
for r=1:size(P,1)
    p=P(r,:); total=0; feasible=true;
    for i=1:n
        if ~isfinite(C(i,p(i))), feasible=false; break; end
        total=total+C(i,p(i));
    end
    if feasible && total<bestCost, bestCost=total; bestPerm=p; end
end
must(~isempty(bestPerm),'No feasible same-type modal assignment exists.');
end

function d=eig_distance(a,b)
d=abs(b-a)/max([1 abs(a) abs(b)]);
end

function m=mode_mac(v,w)
den=real((v'*v)*(w'*w));
if den<=0, m=NaN; else, m=abs(v'*w)^2/den; end
m=min(max(real(m),0),1);
end

function q=modal_row(caseName,m0,m1)
q=empty_modal(); q.caseName=caseName; q.modeType=m0.modeType;
q.M0_real=real(m0.lambda); q.M0_imagPositive=abs(imag(m0.lambda));
q.M1_real=real(m1.lambda); q.M1_imagPositive=abs(imag(m1.lambda));
q.MAC=mode_mac(m0.vector,m1.vector); q.normalizedEigenDistance=eig_distance(m0.lambda,m1.lambda);
q.M0_wn=abs(m0.lambda); q.M1_wn=abs(m1.lambda);
if q.M0_wn>1e-12, q.relativeWnChange=(q.M1_wn-q.M0_wn)/q.M0_wn; q.M0_zeta=-q.M0_real/q.M0_wn; end
if q.M1_wn>1e-12, q.M1_zeta=-q.M1_real/q.M1_wn; end
if isfinite(q.M0_zeta) && abs(q.M0_zeta)>1e-12, q.relativeZetaChange=(q.M1_zeta-q.M0_zeta)/abs(q.M0_zeta); end
if abs(q.M0_real)>1e-12, q.relativeRealPartChange=(q.M1_real-q.M0_real)/abs(q.M0_real); end
if q.M0_imagPositive>1e-12, q.relativeImagMagnitudeChange=(q.M1_imagPositive-q.M0_imagPositive)/q.M0_imagPositive; end
q.M0_topStates=top_states(m0.vector); q.M1_topStates=top_states(m1.vector);
end

function s=top_states(v)
names=["u";"v";"w";"p";"q";"r";"phi";"theta";"psi"];
a=abs(v(:)); idx=(1:numel(a))'; z=sortrows([-a -idx],[1 2]); pick=-z(1:3,2);
s=string(sprintf('%s:%.3f;%s:%.3f;%s:%.3f',char(names(pick(1))),a(pick(1)), ...
    char(names(pick(2))),a(pick(2)),char(names(pick(3))),a(pick(3))));
end

function R=order_like_frozen(Rraw,F)
rows=repmat(empty_modal(),height(F),1); used=false(height(Rraw),1);
for k=1:height(F)
    cand=find(Rraw.caseName==F.caseName(k) & Rraw.modeType==F.modeType(k) & ~used);
    must(~isempty(cand),'Frozen row has no reproduced same-type candidate.');
    target=complex(F.M0_real(k),F.M0_imagPositive(k));
    d=abs(complex(Rraw.M0_real(cand),Rraw.M0_imagPositive(cand))-target);
    [dmin,ii]=min(d); pick=cand(ii);
    must(dmin<1e-8,'Reproduced M0 mode cannot be aligned to frozen ordering.');
    used(pick)=true; q=table_to_modal(Rraw,pick); q.matchedMode=F.matchedMode(k); rows(k)=q;
end
must(all(used),'Some reproduced modes were not ordered.'); R=struct2table(rows,'AsArray',true);
end

function V=validate_against_frozen(R,F)
rows=repmat(empty_validation(),height(F),1);
for k=1:height(F)
    q=empty_validation(); q.caseName=F.caseName(k); q.matchedMode=F.matchedMode(k);
    q.modeTypePass=R.modeType(k)==F.modeType(k);
    q.topStatesPass=R.M0_topStates(k)==F.M0_topStates(k) && R.M1_topStates(k)==F.M1_topStates(k);
    [q.numericPass,q.maxNumericAbsError]=numeric_row_match(R,F,k);
    q.rowPass=q.modeTypePass && q.topStatesPass && q.numericPass; rows(k)=q;
end
V=struct2table(rows,'AsArray',true);
end

function [pass,maxErr]=numeric_row_match(R,F,k)
fields={'M0_real','M0_imagPositive','M1_real','M1_imagPositive','MAC','normalizedEigenDistance', ...
    'M0_wn','M1_wn','relativeWnChange','M0_zeta','M1_zeta','relativeZetaChange', ...
    'relativeRealPartChange','relativeImagMagnitudeChange'};
pass=true; maxErr=0; tol=1e-8;
for i=1:numel(fields)
    a=R.(fields{i})(k); b=F.(fields{i})(k);
    if isnan(a)&&isnan(b), continue; end
    if xor(isnan(a),isnan(b)), pass=false; maxErr=Inf; continue; end
    e=abs(a-b); maxErr=max(maxErr,e); if e>tol, pass=false; end
end
end

function q=table_to_modal(T,k)
q=empty_modal(); f=fieldnames(q); for i=1:numel(f), q.(f{i})=T.(f{i})(k); end
end
function must(tf,msg), if ~tf, error('Stage2ModalRepro:Contract',msg); end, end
function q=empty_mode(), q=struct('lambda',complex(NaN,NaN),'vector',complex(NaN(9,1),NaN(9,1)),'modeType',"",'eigIndex',NaN); end
function q=empty_modal(), q=struct('caseName',"",'matchedMode',NaN,'modeType',"",'M0_real',NaN,'M0_imagPositive',NaN,'M1_real',NaN,'M1_imagPositive',NaN,'MAC',NaN,'normalizedEigenDistance',NaN,'M0_wn',NaN,'M1_wn',NaN,'relativeWnChange',NaN,'M0_zeta',NaN,'M1_zeta',NaN,'relativeZetaChange',NaN,'relativeRealPartChange',NaN,'relativeImagMagnitudeChange',NaN,'M0_topStates',"",'M1_topStates',""); end
function q=empty_cost(), q=struct('caseName',"",'M0canonicalIndex',NaN,'M1canonicalIndex',NaN,'M0modeType',"",'M1modeType',"",'compatibleType',false,'normalizedEigenDistance',NaN,'MAC',NaN,'assignmentCost',NaN,'selected',false); end
function q=empty_assignment(), q=struct('caseName',"",'M0canonicalIndex',NaN,'M1canonicalIndex',NaN,'modeType',"",'normalizedEigenDistance',NaN,'MAC',NaN,'assignmentCost',NaN); end
function q=empty_validation(), q=struct('caseName',"",'matchedMode',NaN,'modeTypePass',false,'topStatesPass',false,'numericPass',false,'maxNumericAbsError',NaN,'rowPass',false); end
