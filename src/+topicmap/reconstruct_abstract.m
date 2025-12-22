function absText = reconstruct_abstract(inv)
%TOPICMAP.RECONSTRUCT_ABSTRACT
% Reconstruct abstract text from OpenAlex abstract_inverted_index.
%
% absText = topicmap.reconstruct_abstract(inv)
%
% Design goals:
% - Fail-safe: never throw for bad inputs
% - Do NOT allocate by max(pos) (pos can be huge / sparse)
% - Order by position only; ignore absolute gaps
%
% Input:
%   inv : struct where each field is a token and value is numeric vector of positions
%
% Output:
%   absText : string scalar ("" if missing/invalid)

    absText = "";

    % ---- Guard clauses ----
    if nargin < 1 || isempty(inv) || ~isstruct(inv)
        return;
    end

    fns = fieldnames(inv);
    if isempty(fns)
        return;
    end

    % ---- Collect (pos, token) pairs ----
    posAll = [];
    tokAll = strings(0,1);

    for i = 1:numel(fns)
        tok = fns{i};
        try
            v = inv.(tok);
        catch
            continue;
        end

        if isempty(v)
            continue;
        end

        % Ensure numeric positions
        if ~isnumeric(v)
            continue;
        end

        v = double(v(:));

        % Keep only finite, non-negative positions
        ok = isfinite(v) & v >= 0;
        if ~any(ok)
            continue;
        end

        v = floor(v(ok)); % OpenAlex positions are integers; be explicit

        posAll = [posAll; v]; %#ok<AGROW>
        tokAll = [tokAll; repmat(string(tok), numel(v), 1)]; %#ok<AGROW>
    end

    if isempty(posAll)
        return;
    end

    % ---- Sort by position ----
    [posSorted, idx] = sort(posAll); %#ok<ASGLU>
    tokSorted = tokAll(idx);

    % ---- Build text without sparse indexing ----
    % We only care about order, not absolute position gaps
    absText = strjoin(tokSorted, " ");
end
