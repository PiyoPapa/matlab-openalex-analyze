function [text, meta] = extract_text(W, policy, maxChars)
%TOPICMAP.EXTRACT_TEXT Build embedding text from works struct array.
%
% [text, meta] = topicmap.extract_text(W, policy, maxChars)
% policy: "title+abstract" | "title"
% Returns:
%   text: string (n x 1)
%   meta: struct with fields work_id, title, abstract, year (if available)

    arguments
        W (:,1) struct
        policy (1,1) string = "title+abstract"
        maxChars (1,1) double = 6000
    end

    n = numel(W);
    text = strings(n,1);

    meta = struct();
    meta.work_id = strings(n,1);
    meta.title   = strings(n,1);
    meta.abstract= strings(n,1);
    meta.year    = nan(n,1);

    for i = 1:n
        wi = W(i);

        % work id
        if isfield(wi,"id"); meta.work_id(i) = string(wi.id); end

        % title
        if isfield(wi,"title"); meta.title(i) = toScalarString_(wi.title); end

        % year (optional)
        if isfield(wi,"publication_year"); meta.year(i) = double(wi.publication_year); end

        % abstract reconstruction
        absText = "";
        if isfield(wi,"abstract_inverted_index")
            absText = topicmap.reconstruct_abstract(wi.abstract_inverted_index);
        end
        meta.abstract(i) = absText;

        switch lower(policy)
            case "title+abstract"
                s = strtrim(meta.title(i));
                a = strtrim(meta.abstract(i));
                if strlength(a) > 0
                    s = strtrim(s + newline + a);
                end
            case "title"
                s = strtrim(meta.title(i));
            otherwise
                error("topicmap:extract_text:BadPolicy", "Unknown policy: %s", policy);
        end

        if strlength(s) > maxChars
            s = extractBefore(s, maxChars+1);
        end
        text(i) = s;
    end
end

function s = toScalarString_(x)
% Force any "title-like" input into a single string scalar.
% Prevents "Left and right sides have a different number of elements" on assignment.
if isempty(x)
    s = "";
    return;
end
try
    sx = string(x);
catch
    s = "";
    return;
end
if isscalar(sx)
    s = sx;
    return;
end
sx = sx(:);
sx = sx(strlength(sx) > 0);
if isempty(sx)
    s = "";
else
    s = strjoin(sx, " ");
end
end