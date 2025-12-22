%% dev_reconstruct_abstract
% Dev harness to validate OpenAlex abstract_inverted_index -> text reconstruction.
% Uses topicmap functions to validate: abstract_inverted_index -> reconstructed text -> cleaned text.

clear; clc;

%% 0) JSONL path (auto-detect)
jsonlName = "openalex_MATLAB_cursor_en_1000.standard.jsonl";

% 1) If user put it in current folder, use it
if isfile(jsonlName)
    jsonlPath = jsonlName;
else
    % 2) Try to find it under the hub (or current project) recursively
    hits = dir("**/" + jsonlName);
    if isempty(hits)
        error("topicmap:dev:MissingJSONL", ...
            "JSONL not found. Put %s in the current folder, or set jsonlPath to the full path.", jsonlName);
    end
    % If multiple, pick the newest
    [~, idx] = max([hits.datenum]);
    jsonlPath = fullfile(hits(idx).folder, hits(idx).name);
end

fprintf("Using JSONL: %s\n", jsonlPath);


%% 0+) Load JSONL quickly (line-by-line)
txt = fileread(jsonlPath);
lines = regexp(txt, '\r\n|\n|\r', 'split');
lines = string(lines);
lines = lines(strlength(strtrim(lines))>0);

n = numel(lines);
fprintf("Loaded %d JSONL lines\n", n);

% Sample a few indices (spread across the file)
pick = unique(round(linspace(1, n, min(20,n))));

%% 2) Parse + reconstruct for selected records
nOK = 0; nEmpty = 0; nFail = 0;
nHasInv = 0;
nHasInvNonEmpty = 0;

for ii = pick
    try
        w = jsondecode(char(lines(ii)));

        title = "";
        if isfield(w,"title"); title = string(w.title); end
        wid = "";
        if isfield(w,"id"); wid = string(w.id); end

        inv = [];
        if isfield(w,"abstract_inverted_index")
            inv = w.abstract_inverted_index;
            nHasInv = nHasInv + 1;
            % count only when it looks non-empty (struct with at least one field)
            if isstruct(inv) && ~isempty(fieldnames(inv))
                nHasInvNonEmpty = nHasInvNonEmpty + 1;
            end
        end

        % reconstruction + minimal cleaning (new topicmap functions)
        absRaw = topicmap.reconstruct_abstract(inv);
        absClean = topicmap.clean_text(absRaw);

        if strlength(absRaw)==0
            nEmpty = nEmpty + 1;
        else
            nOK = nOK + 1;
        end

        fprintf("\n[%d] id: %s\n", ii, truncate_(wid, 80));
        fprintf("  title: %s\n", truncate_(title, 80));
        fprintf("  raw   len=%d : %s\n", strlength(absRaw),   truncate_(absRaw,   120));
        fprintf("  clean len=%d : %s\n", strlength(absClean), truncate_(absClean, 120));

        % Basic sanity checks (non-fatal)
        if strlength(absRaw) > 0 && strlength(absClean)==0
            fprintf("  NOTE: cleaned became empty (short/noisy) -> check thresholds\n");
        end

    catch ME
        nFail = nFail + 1;
        fprintf("\n[%d] FAIL: %s\n", ii, ME.message);
        % If you want full stack:
        % disp(getReport(ME,"extended"));
    end
end

fprintf("\nSummary (tested=%d): has_inv=%d, OK(raw>0)=%d, Empty(raw==0)=%d, Fail=%d\n", ...
    numel(pick), nHasInv, nOK, nEmpty, nFail);
fprintf("  has_inv_nonempty=%d\n", nHasInvNonEmpty);

%% --- helper ---
function s = truncate_(s, n)
    s = string(s);
    if strlength(s) <= n
        return;
    end
    s = extractBefore(s, n+1) + " ...";
end
