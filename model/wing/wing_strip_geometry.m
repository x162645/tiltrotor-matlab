function strips = wing_strip_geometry(P)
%WING_STRIP_GEOMETRY Build constant-chord spanwise wing strips.

n = 24;
if isfield(P.wing, 'fullAngleStripCount')
    n = P.wing.fullAngleStripCount;
end
if ~(isnumeric(n) && isscalar(n) && isfinite(n) && n >= 4 && n == round(n))
    error('wing_strip_geometry:InvalidStripCount', ...
        'P.wing.fullAngleStripCount must be an integer >= 4.');
end
span = P.wing.b;
if ~(isfinite(span) && span > 0)
    error('wing_strip_geometry:InvalidSpan', 'P.wing.b must be positive.');
end
edges = linspace(-span/2, span/2, n + 1);
y = 0.5*(edges(1:end-1) + edges(2:end));
area = (P.wing.S / n) * ones(n, 1);
rAC = [P.wing.xAC*ones(n,1), y(:), P.wing.zAC*ones(n,1)];
strips = struct();
strips.count = n;
strips.edges = edges(:);
strips.y = y(:);
strips.area = area;
strips.rAC = rAC;
strips.chord = P.wing.c * ones(n, 1);
end
