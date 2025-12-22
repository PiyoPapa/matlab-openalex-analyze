function absText = reconstruct_abstract(abstract_inverted_index)
%TOPICMAP.RECONSTRUCT_ABSTRACT Reconstruct abstract from OpenAlex inverted index.
%
% absText = topicmap.reconstruct_abstract(idx)
% idx is a struct: idx.(token) = [pos1 pos2 ...]
% Returns reconstructed abstract as a single string.

    if isempty(abstract_inverted_index)
        absText = "";
        return;
    end
    if ~isstruct(abstract_inverted_index)
        absText = "";
        return;
    end

    tokens = string(fieldnames(abstract_inverted_index));
    if isempty(tokens)
        absText = "";
        return;
    end

    % Collect (pos, token)
    posAll = [];
    tokAll = strings(0,1);

    for t = tokens.'
        v = abstract_inverted_index.(t);
        if isempty(v)
            continue;
        end
        % v should be numeric vector
        v = double(v(:));
        posAll = [posAll; v]; %#ok<AGROW>
        tokAll = [tokAll; repmat(t, numel(v), 1)]; %#ok<AGROW>
    end

    if isempty(posAll)
        absText = "";
        return;
    end

    [posSorted, order] = sort(posAll);
    tokSorted = tokAll(order);

    % Place tokens at positions
    maxPos = posSorted(end);
    seq = strings(maxPos+1,1);
    seq(:) = "";
    seq(posSorted+1) = tokSorted;

    % Fill gaps with empty, then join with spaces, then normalize whitespace
    s = strjoin(seq, " ");
    s = regexprep(s, "\s+", " ");
    absText = strtrim(s);
end
