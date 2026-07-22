function results = evaluate_generic_trim_stability(dbA,dbC2,Pbase,Pc2)
%EVALUATE_GENERIC_TRIM_STABILITY Representative post-freeze A/C2 comparison.
% Linearization is restricted to points credible in both variants.  Results
% are internal low-order-model derivatives/modes, not handling-quality proof.

ids={'B15_V020';'B45_V035';'B75_V080'};
variants={'MODEL_A';'MODEL_C2'};
databases={dbA,dbC2}; parameters={Pbase,Pc2};
derivativeRows={}; eigenTables=cell(6,1); models=cell(6,1); n=0;
spec={1,1,'Xu';1,3,'Xw';3,1,'Zu';3,3,'Zw';5,3,'Mw';5,5,'Mq'; ...
    2,2,'Yv';4,4,'Lp';6,6,'Nr';4,2,'Lv';6,2,'Nv'};
for v=1:2
    D=databases{v}; P=parameters{v};
    for j=1:numel(ids)
        k=find(strcmp(D.summary.pointId,ids{j}),1);
        if isempty(k) || ~strcmp(D.points(k).status,'CREDIBLE')
            error('evaluate_generic_trim_stability:NonCrediblePoint', ...
                '%s is not credible in %s.',ids{j},variants{v});
        end
        n=n+1;
        L=linearize_berger13_trim_point(D.points(k).trim,P);
        modalError=''; M=[];
        try
            M=analyze_berger13_modes(L.symdiff.A,L.symdiff.B, ...
                L.symdiff.stateNames,L.symdiff.inputNames);
        catch ME
            modalError=sprintf('%s: %s',ME.identifier,ME.message);
        end
        models{n}=struct('variant',variants{v},'pointId',ids{j}, ...
            'linear',L,'modal',M,'modalError',modalError);
        for q=1:size(spec,1)
            derivativeRows(end+1,:)={variants{v},ids{j},spec{q,3}, ...
                L.symdiff.A(spec{q,1},spec{q,2}), ...
                spec{q,1},spec{q,2},L.maximumRelativeStepVariation, ...
                L.finiteReal}; %#ok<AGROW>
        end
        T=modal_summary(L.symdiff.A,M,modalError);
        T.variant=repmat(variants(v),height(T),1);
        T.pointId=repmat(ids(j),height(T),1);
        eigenTables{n}=T;
    end
end
results.derivatives=cell2table(derivativeRows,'VariableNames', ...
    {'variant','pointId','derivativeName','value','rowIndex', ...
    'columnIndex','maximumRelativeStepVariation','finiteReal'});
results.eigenvalues=vertcat(eigenTables{1:n});
results.models=models(1:n);
results.claimBoundary=['Representative internal linearizations at credible ' ...
    'trim points; not external validation or handling-quality acceptance.'];
end

function T=modal_summary(A,M,modalError)
[~,D]=eig(A); lambda=diag(D); n=numel(lambda);
localModeIndex=(1:n).';
realPartPerSecond=real(lambda); imagPartRadPerSecond=imag(lambda);
naturalFrequencyRadPerSecond=abs(lambda);
dampingRatio=-realPartPerSecond./max(naturalFrequencyRadPerSecond,eps);
frequencyHz=abs(imagPartRadPerSecond)/(2*pi);
stable=realPartPerSecond<0;
if isempty(M)
    modeName=repmat({'UNCLASSIFIED_ILL_CONDITIONED_EIGENVECTORS'},n,1);
    headingIntegrator=false(n,1);
    analysisStatus=repmat({'RAW_EIGENVALUES_ONLY'},n,1);
    analysisMessage=repmat({modalError},n,1);
else
    modeName=M.table.modeName;
    headingIntegrator=M.table.headingIntegrator;
    analysisStatus=repmat({'PARTICIPATION_CLASSIFIED'},n,1);
    analysisMessage=repmat({''},n,1);
end
T=table(localModeIndex,modeName,realPartPerSecond, ...
    imagPartRadPerSecond,dampingRatio,naturalFrequencyRadPerSecond, ...
    frequencyHz,headingIntegrator,stable,analysisStatus,analysisMessage);
end
