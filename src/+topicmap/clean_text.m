function s = clean_text(s)
%TOPICMAP.CLEAN_TEXT
% Minimal, embedding-safe text normalization.
%
% s = topicmap.clean_text(s)
%
% Policy:
% - Do NOT aggressively delete information
% - Normalize whitespace
% - Remove obvious HTML artifacts
% - Keep numbers and short tokens (important for science text)

    if nargin < 1
        s = "";
        return;
    end

    % Accept char / string
    try
        s = string(s);
    catch
        s = "";
        return;
    end

    if strlength(s) == 0
        return;
    end

    % ---- Basic normalization ----
    % Normalize newlines and tabs to space
    s = regexprep(s, '[\r\n\t]+', ' ');

    % Remove HTML tags (very conservative)
    s = regexprep(s, '<[^>]+>', ' ');

    % Decode common HTML entities (minimal set)
    s = strrep(s, '&nbsp;', ' ');
    s = strrep(s, '&amp;',  '&');
    s = strrep(s, '&lt;',   '<');
    s = strrep(s, '&gt;',   '>');

    % Collapse multiple spaces
    s = regexprep(s, '\s+', ' ');

    % Trim
    s = strtrim(s);
end
