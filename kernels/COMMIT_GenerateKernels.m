%
% Generate the high-resolution atoms in the dictionary.
% Dispatch to the proper function, depending on the model.
%
% Parameters
% ----------
% doRegenerate : boolean
%   Regenerate kernels if they already exist
% lmax : unsigned int
%   Maximum spherical harmonics order to use for the rotation procedure
%
function COMMIT_GenerateKernels( doRegenerate, lmax )
    if nargin < 1, doRegenerate = false; end
    if nargin < 2, lmax = 12; end
    global CONFIG COMMIT_data_path

    fprintf( '\n-> Generating kernels for protocol "%s":\n', CONFIG.protocol );

    % check if kernels were already generated
    ATOMS_path = fullfile(COMMIT_data_path,CONFIG.protocol,'kernels',CONFIG.model.id);
    tmp = dir( fullfile(ATOMS_path,'A_*.mat') );
    if ( numel(tmp) > 0 & doRegenerate==false )
        fprintf( '   [ Kernels already computed. Set "doRegenerate=true" to force regeneration ]\n' )
        return
    end
    [~,~,~] = mkdir( ATOMS_path );
    delete( fullfile(ATOMS_path,'*') );

    % check if original scheme exists
    if ~exist( CONFIG.schemeFilename, 'file' ) || isempty(CONFIG.scheme)
        error( '[COMMIT_GenerateKernels] Scheme file "%s" not found', CONFIG.schemeFilename )
    end

    % check if auxiliary matrices have been precomputed
    auxFilename = fullfile(COMMIT_data_path,sprintf('AUX_matrices__lmax=%d.mat',lmax) );
    if ~exist( auxFilename, 'file' )
        error( '[COMMIT_GenerateKernels] Auxiliary matrices "%s" not found', auxFilename )
    else
        AUX = load( auxFilename );
    end


    % Precompute aux data structures
    % ==============================
    idx_IN  = [];
    idx_OUT = [];
    rowIN  = 1;
    rowOUT = 1;
    nSH = (lmax+1)*(lmax+2)/2;
    for i = 1:numel(CONFIG.scheme.shells)
        idx_IN{end+1}  = rowIN  : rowIN +500-1;
        idx_OUT{end+1} = rowOUT : rowOUT+nSH-1;
        rowIN  = rowIN+500;
        rowOUT = rowOUT+nSH;
    end

    
    % Dispatch to the right handler for each model
    % ============================================
    if ~isempty(CONFIG.model)
        TIME = tic();
        fprintf( '\t* Creating high-resolution scheme... ' );
        COMMIT_CreateHighResolutionScheme( fullfile(ATOMS_path,'protocol_HR.scheme'), CONFIG.model.bscale );
        schemeHR   = COMMIT_LoadScheme( fullfile(ATOMS_path,'protocol_HR.scheme'), CONFIG.b0_thr );
        fprintf( '[OK]\n' );

        fprintf( '\t* Simulating kernels with "%s" model:\n', CONFIG.model.name );
        CONFIG.model.GenerateKernels( ATOMS_path, schemeHR, AUX, idx_IN, idx_OUT );
        fprintf( '\t  [ %.1f seconds ]\n', toc(TIME) );
    else
        error( '[COMMIT_GenerateKernels] Model not set' )
    end


    fprintf( '   [ DONE ]\n' );
end
