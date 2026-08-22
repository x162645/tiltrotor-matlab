function T = build_xv15_public_second_pass_audit()
%BUILD_XV15_PUBLIC_SECOND_PASS_AUDIT Export the second-pass source registry.
% One row is one public-data fact or one explicit interface/model-form gate.

reference = params_xv15_public_reference_second_pass();
T = struct2table(reference.records);

if ~isempty(T)
    T.recordId = strcat('XV15-SP-',compose('%03d',(1:height(T)).'));
    T = movevars(T,'recordId','Before',1);
end
end
