function W = read_pipeline_jsonl(jsonlPath, varargin)
%TOPICMAP.READ_PIPELINE_JSONL Read OpenAlex *standard* JSONL (1 work per line).
%
%   W = topicmap.read_pipeline_jsonl(jsonlPath)
%   W = topicmap.read_pipeline_jsonl(jsonlPath, 'maxRecords', N, 'verbose', true)
%
% Notes
% - This function is streaming-first (does not fileread the whole file).
% - It normalizes missing fields across records to avoid "dissimilar structures" errors.

    p = inputParser;
    p.addRequired('jsonlPath', @(x) (isstring(x)||ischar(x)) && strlength(string(x))>0);
    p.addParameter('maxRecords', inf, @(x) isnumeric(x) && isscalar(x) && x>=1);
    p.addParameter('verbose', false, @(x) islogical(x) && isscalar(x));
    p.parse(jsonlPath, varargin{:});

    jsonlPath = string(p.Results.jsonlPath);
    maxRecords = double(p.Results.maxRecords);
    verbose = logical(p.Results.verbose);

    assert(isfile(jsonlPath), "JSONL not found: %s", jsonlPath);

    fid = fopen(jsonlPath, 'r');
    assert(fid>=0, "Failed to open JSONL: %s", jsonlPath);
    c = onCleanup(@() fclose(fid));

    S = {}; %#ok<CCAT>
    allFields = string.empty(0,1);

    i = 0;
    while true
        line = fgetl(fid);
        if ~ischar(line) && ~isstring(line)
            break;
        end
        line = string(line);
        if strlength(strtrim(line))==0
            continue;
        end

        i = i + 1;
        if i > maxRecords
            break;
        end

        try
            si = jsondecode(char(line));
            if ~isstruct(si)
                error("Decoded JSON is not a struct.");
            end
            S{end+1,1} = si; %#ok<AGROW>
            allFields = union(allFields, string(fieldnames(si)));
        catch ME
            error("topicmap:jsonl:Parse", "Failed to parse JSONL at line %d: %s", i, ME.message);
        end

        if verbose && mod(i, 5000)==0
            fprintf("[read_pipeline_jsonl] parsed %d lines...\n", i);
        end
    end

    n = numel(S);
    if n==0
        W = struct([]);
        return;
    end

    % Normalize fields across all records
    for j = 1:n
        sj = S{j};
        f = string(fieldnames(sj));
        missing = setdiff(allFields, f);
        for k = 1:numel(missing)
            sj.(missing(k)) = [];
        end
        S{j} = sj;
    end

    W = vertcat(S{:});
end