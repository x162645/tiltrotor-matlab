function results = run_stage2_accepted_modal_matching_reproduction(outputRoot)
%RUN_STAGE2_ACCEPTED_MODAL_MATCHING_REPRODUCTION
% Reproduce the accepted B15/B75 M0->M1 modal matching entirely in MATLAB.
%
% Evidence contract:
%   * consume only the frozen fine-scale full-A matrices already accepted by
%     the Stage-2 dynamic comparability gate;
%   * do not re-trim, re-linearize, continue endpoints, or alter physics,
%     numerical tolerances, bounds, controls, or model parameters;
%   * collapse each real A matrix into real/integrator modes plus one
%     representative (positive-imaginary member) of each conjugate pair;
%   * match M0 to M1 by global minimum total cost over all modal permutations,
%       cost = normalized eigenvalue distance + (1 - MAC),
%     with incompatible mode types assigned infinite cost;
%   * use the frozen accepted matching table only to order/validate the
%     independently reproduced pairs, never to choose the assignment.
%
% The implementation uses only base MATLAB functionality available in R2021a.

if nargin < 1 || isempty(outputRoot)
    outputRoot = fullfile(pwd,'results','stage2_accepted_modal_matching_reproduction');
end
if ~exist(outputRoot,'dir'), mkdir(outputRoot); end

here = fileparts(mfilename('fullpath'));
evidenceDir = fullfile(here,'evidence');
matrixPath = fullfile(evidenceDir,'STAGE2_ACCEPTED_FULL_A_MATRICES_SCALE05.csv');
frozenPath = fullfile(evidenceDir,'STAGE2_ACCEPTED_MODAL_MATCHING.csv');
E = readtable(matrixPath,'TextType','string');
F = readtable(frozenPath,'TextType','string');

validate_matrix_snapshot(E);
cases = ["B15_V020";"B75_V080"];
rawRows = repmat(empty_modal_row(),0,1);
costRows = repmat(empty_cost_row(),0,1);
assignmentRows = repmat(empty_assignment_row(),0,1);

for c = 1:numel(cases)
    caseName = cases(c);
    A0 = reconstruct_A(E,caseName,"M0_MATCHED_PRODUCTION");
    A1 = reconstruct_A(E,caseName,"M1_EVIDENCE_V1_PROPAGATION");
    m0 = canonical_modes(A0);
    m1 = canonical_modes(A1);
    assert(numel(m0)==numel(m1),'Stage2ModalRepro:ModeCountMismatch');

    [perm,C] = minimum_cost_assignment(m0,m1);
    for i = 1:numel(m0)
        for j = 1:numel(m1)
            cr = empty_cost_row();
            cr.caseName = caseName; cr.M0canonicalIndex = i; cr.M1canonicalIndex = j;
            cr.M0modeType = m0(i).modeType; cr.M1modeType = m1(j).modeType;
            cr.compatibleType = m0(i).modeType==m1(j).modeType;
            if cr.compatibleType
                cr.normalizedEigenDistance = normalized_eigen_distance(m0(i).lambda,m1(j).lambda);
                cr.MAC = eigenvector_mac(m0(i).vector,m1(j).vector);
                cr.assignmentCost = C(i,j);
            end
            cr.selected = perm(i)==j;
            costRows(end+1,1) = cr; %#ok<AGROW>
        end
    end

    for i = 1:numel(m0)
        j = perm(i);
        rawRows(end+1,1) = build_modal_row(caseName,m0(i),m1(j)); %#ok<AGROW>
        ar = empty_assignment_row(); ar.caseName=caseName; ar.M0canonicalIndex=i; ar.M1canonicalIndex=j;
        ar.modeType=m0(i).modeType; ar.normalizedEigenDistance=normalized_eigen_distance(m0(i).lambda,m1(j).lambda);
        ar.MAC=eigenvector_mac(m0(i).vector,m1(j).vector); ar.assignmentCost=C(i,j);
        assignmentRows(end+1,1)=ar; %#ok<AGROW>
    end
end

rawTable = struct2table(rawRows,'AsArray',true);
orderedRows = repmat(empty_modal_row(),height(F),1);
used = false(height(rawTable),1);
for k = 1:height(F)
    sameCase = rawTable.caseName==F.caseName(k);
    sameType = rawTable.modeType==F.modeType(k);
    candidates = find(sameCase & sameType & ~used);
    assert(~isempty(candidates),'Stage2ModalRepro:FrozenRowHasNoCandidate');
    target = complex(F.M0_real(k),F.M0_imagPositive(k));
    d = abs(complex(rawTable.M0_real(candidates),rawTable.M0_imagPositive(candidates))-target);
    [dmin,ii] = min(d); pick = candidates(ii);
    assert(dmin < 1e-8,'Stage2ModalRepro:FrozenOrderingMismatch');
    used(pick)=true;
    rr = table_row_to_struct(rawTable,pick);
    rr.matchedMode = F.matchedMode(k);
    orderedRows(k)=rr;
end
assert(all(used),'Stage2ModalRepro:UnorderedReproducedRows');
reproduced = struct2table(orderedRows,'AsArray',true);

validationRows = repmat(empty_validation_row(),height(F),1);
for k=1:height(F)
    vr=empty_validation_row(); vr.caseName=F.caseName(k); vr.matchedMode=F.matchedMode(k);
    vr.modeTypePass = reproduced.modeType(k)==F.modeType(k);
    vr.topStatesPass = reproduced.M0_topStates(k)==F.M0_topStates(k) && reproduced.M1_topStates(k)==F.M1_topStates(k);
    [vr.numericPass,vr.maxNumericAbsError] = compare_numeric_row(reproduced,F,k);
    vr.rowPass = vr.modeTypePass && vr.topStatesPass && vr.numericPass;
    validationRows(k)=vr;
end
validation = struct2table(validationRows,'AsArray',true);

costTable = struct2table(costRows,'AsArray',true);
assignmentTable = struct2table(assignmentRows,'AsArray',true);
summary = table(height(E),height(reproduced),sum(validation.rowPass),max(validation.maxNumericAbsError), ...
    'VariableNames',{'matrixElementCount','reproducedModeCount','validatedModeCount','maxNumericAbsError'});

writetable(reproduced,fullfile(outputRoot,'STAGE2_REPRODUCED_MODAL_MATCHING.csv'));
writetable(validation,fullfile(outputRoot,'STAGE2_MODAL_MATCHING_VALIDATION.csv'));
writetable(costTable,fullfile(outputRoot,'STAGE2_MODAL_MATCHING_COST_MATRIX.csv'));
writetable(assignmentTable,fullfile(outputRoot,'STAGE2_MODAL_MATCHING_ASSIGNMENT.csv'));
writetable(summary,fullfile(outputRoot,'STAGE2_MODAL_MATCHING_REPRODUCTION_SUMMARY.csv'));
metadata=table(["FROZEN_ACCEPTED_FINE_SCALE_FULL_A_ONLY"; ...
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

assert(height(E)==324,'Stage2ModalRepro:MatrixSnapshotNot324');
assert(height(reproduced)==13,'Stage2ModalRepro:UnexpectedReproducedModeCount');
assert(all(validation.rowPass),'Stage2ModalRepro:FrozenMatchingNotReproduced');

results=struct('reproduced',reproduced,'validation',validation,'costMatrix',costTable, ...
    'assignment',assignmentTable,'summary',summary,'metadata',metadata, ...
    'claimBoundary','WHOLE_AIRCRAFT_PROPAGATION_SENSITIVITY_NOT_XV15_AIRCRAFT_VALIDATION');
save(fullfile(outputRoot,'STAGE2_ACCEPTED_MODAL_MATCHING_REPRODUCTION.mat'),'results');
disp(summary); disp(validation);
end

function validate_matrix_snapshot(E)
assert(height(E)==324,'Stage2ModalRepro:MatrixElementCount');
assert(all(E.matrixName=="A"),'Stage2ModalRepro:NonAMatrixEvidence');
assert(all(abs(E.stepScale-0.5)<eps),'Stage2ModalRepro:NonFineScaleEvidence');
cases=["B15_V020";"B75_V080"]; models=["M0_MATCHED_PRODUCTION";"M1_EVIDENCE_V1_PROPAGATION"];
for c=1:2
    for m=1:2
        g=E(E.caseName==cases(c) & E.modelIdentity==models(m),:);
        assert(height(g)==81,'Stage2ModalRepro:IncompleteMatrixBlock');
        key=(g.rowIndex-1)*9+g.columnIndex;
        assert(numel(unique(key))==81 && min(key)==1 && max(key)==81,'Stage2ModalRepro:DuplicateOrMissingMatrixElement');
        assert(all(isfinite(g.value)),'Stage2ModalRepro:NonFiniteMatrixEvidence');
    end
end
assert(all(E.sourceArtifactId(E.caseName=="B15_V020")==9781737622),'Stage2ModalRepro:B15Provenance');
assert(all(E.sourceArtifactId(E.caseName=="B75_V080")==9781761914),'Stage2ModalRepro:B75Provenance');
assert(all(E.sourceArtifactDigest(E.caseName=="B15_V020")=="sha256:c12863890c26e57a614580df38db7a4a830496ca0592092da002087c7afab57f"),'Stage2ModalRepro:B15Digest');
assert(all(E.sourceArtifactDigest(E.caseName=="B75_V080")=="sha256:33d7596ee0111e6dd0b3b4ec754ef3399395cdf8fa3ab801cef23376b98d765c"),'Stage2ModalRepro:B75Digest');
end

function A=reconstruct_A(E,caseName,modelIdentity)
g=E(E.caseName==caseName & E.modelIdentity==modelIdentity,:);
assert(height(g)==81,'Stage2ModalRepro:ReconstructIncomplete');
A=NaN(9,9);
for k=1:height(g), A(g.rowIndex(k),g.columnIndex(k))=g.value(k); end
assert(all(isfinite(A(:))) && isreal(A),'Stage2ModalRepro:ReconstructInvalid');
end

function modes=canonical_modes(A)
[V,D]=eig(A); lam=diag(D); tol=1e-10;
modes=repmat(empty_mode(),0,1);
for k=1:numel(lam)
    z=lam(k);
    if abs(imag(z))<=tol
        r=empty_mode(); r.lambda=complex(real(z),0); r.vector=V(:,k); r.eigIndex=k;
        if abs(z)<=tol, r.modeType="INTEGRATOR"; else, r.modeType="REAL"; end
        modes(end+1,1)=r; %#ok<AGROW>
    elseif imag(z)>tol
        r=empty_mode(); r.lambda=z; r.vector=V(:,k); r.eigIndex=k; r.modeType="COMPLEX_PAIR";
        modes(end+1,1)=r; %#ok<AGROW>
    end
end
assert(sum([modes.modeType]=="INTEGRATOR")==1,'Stage2ModalRepro:ExpectedOneIntegrator');
end

function [bestPerm,C]=minimum_cost_assignment(m0,m1)
n=numel(m0); assert(n==numel(m1),'Stage2ModalRepro:AssignmentSize');
C=Inf(n,n);
for i=1:n
    for j=1:n
        if m0(i).modeType==m1(j).modeType
            C(i,j)=normalized_eigen_distance(m0(i).lambda,m1(j).lambda)+(1-eigenvector_mac(m0(i).vector,m1(j).vector));
        end
    end
end
P=perms(1:n); bestCost=Inf; bestPerm=[];
for r=1:size(P,1)
    p=P(r,:); total=0; feasible=true;
    for i=1:n
        cij=C(i,p(i));
        if ~isfinite(cij), feasible=false; break; end
        total=total+cij;
    end
    if feasible && total<bestCost
        bestCost=total; bestPerm=p;
    end
end
assert(~isempty(bestPerm),'Stage2ModalRepro:NoFeasibleAssignment');
end

function d=normalized_eigen_distance(a,b)
d=abs(b-a)/max([1 abs(a) abs(b)]);
end

function m=eigenvector_mac(v,w)
den=real((v'*v)*(w'*w));
if den<=0, m=NaN; else, m=abs(v'*w)^2/den; end
m=min(max(real(m),0),1);
end

function r=build_modal_row(caseName,m0,m1)
r=empty_modal_row(); r.caseName=caseName; r.modeType=m0.modeType;
r.M0_real=real(m0.lambda); r.M0_imagPositive=abs(imag(m0.lambda));
r.M1_real=real(m1.lambda); r.M1_imagPositive=abs(imag(m1.lambda));
r.MAC=eigenvector_mac(m0.vector,m1.vector); r.normalizedEigenDistance=normalized_eigen_distance(m0.lambda,m1.lambda);
r.M0_wn=abs(m0.lambda); r.M1_wn=abs(m1.lambda);
if r.M0_wn>1e-12, r.relativeWnChange=(r.M1_wn-r.M0_wn)/r.M0_wn; end
if r.M0_wn>1e-12, r.M0_zeta=-r.M0_real/r.M0_wn; end
if r.M1_wn>1e-12, r.M1_zeta=-r.M1_real/r.M1_wn; end
if isfinite(r.M0_zeta) && abs(r.M0_zeta)>1e-12, r.relativeZetaChange=(r.M1_zeta-r.M0_zeta)/abs(r.M0_zeta); end
if abs(r.M0_real)>1e-12, r.relativeRealPartChange=(r.M1_real-r.M0_real)/abs(r.M0_real); end
if r.M0_imagPositive>1e-12, r.relativeImagMagnitudeChange=(r.M1_imagPositive-r.M0_imagPositive)/r.M0_imagPositive; end
r.M0_topStates=top_states(m0.vector); r.M1_topStates=top_states(m1.vector);
end

function s=top_states(v)
names=["u";"v";"w";"p";"q";"r";"phi";"theta";"psi"];
a=abs(v(:)); idx=(1:numel(a))'; order=sortrows([-a -idx],[1 2]); pick=-order(1:3,2);
s=sprintf('%s:%.3f;%s:%.3f;%s:%.3f',char(names(pick(1))),a(pick(1)),char(names(pick(2))),a(pick(2)),char(names(pick(3))),a(pick(3)));
s=string(s);
end

function [pass,maxErr]=compare_numeric_row(R,F,k)
fields={'M0_real','M0_imagPositive','M1_real','M1_imagPositive','MAC','normalizedEigenDistance', ...
    'M0_wn','M1_wn','relativeWnChange','M0_zeta','M1_zeta','relativeZetaChange', ...
    'relativeRealPartChange','relativeImagMagnitudeChange'};
pass=true; maxErr=0; tol=1e-8;
for i=1:numel(fields)
    f=fields{i}; a=R.(f)(k); b=F.(f)(k);
    if isnan(a)&&isnan(b), continue; end
    if xor(isnan(a),isnan(b)), pass=false; maxErr=Inf; continue; end
    e=abs(a-b); maxErr=max(maxErr,e);
    if e>tol, pass=false; end
end
end

function r=table_row_to_struct(T,k)
r=empty_modal_row(); fn=fieldnames(r);
for i=1:numel(fn), r.(fn{i})=T.(fn{i})(k); end
end

function r=empty_mode()
r=struct('lambda',complex(NaN,NaN),'vector',complex(NaN(9,1),NaN(9,1)),'modeType',"",'eigIndex',NaN);
end
function r=empty_modal_row()
r=struct('caseName',"",'matchedMode',NaN,'modeType',"",'M0_real',NaN,'M0_imagPositive',NaN,'M1_real',NaN,'M1_imagPositive',NaN, ...
    'MAC',NaN,'normalizedEigenDistance',NaN,'M0_wn',NaN,'M1_wn',NaN,'relativeWnChange',NaN,'M0_zeta',NaN,'M1_zeta',NaN, ...
    'relativeZetaChange',NaN,'relativeRealPartChange',NaN,'relativeImagMagnitudeChange',NaN,'M0_topStates',"",'M1_topStates',"");
end
function r=empty_cost_row()
r=struct('caseName',"",'M0canonicalIndex',NaN,'M1canonicalIndex',NaN,'M0modeType',"",'M1modeType',"", ...
    'compatibleType',false,'normalizedEigenDistance',NaN,'MAC',NaN,'assignmentCost',NaN,'selected',false);
end
function r=empty_assignment_row()
r=struct('caseName',"",'M0canonicalIndex',NaN,'M1canonicalIndex',NaN,'modeType',"",'normalizedEigenDistance',NaN,'MAC',NaN,'assignmentCost',NaN);
end
function r=empty_validation_row()
r=struct('caseName',"",'matchedMode',NaN,'modeTypePass',false,'topStatesPass',false,'numericPass',false,'maxNumericAbsError',NaN,'rowPass',false);
end
