function mesh = bf_sources_mesh(BF, S)
% Generate cortical mesh
% Copyright (C) 2013 Wellcome Trust Centre for Neuroimaging

% Vladimir Litvak
% $Id$

%--------------------------------------------------------------------------
if nargin == 0
    orient         = cfg_menu;
    orient.tag     = 'orient';
    orient.name    = 'How to orient the sources';
    orient.labels  = {'Unoriented', 'Original', 'Downsampled'};
    orient.values  = {'unoriented', 'original', 'downsampled'};
    orient.val     = {'unoriented'};
        
    fdownsample      = cfg_entry;
    fdownsample.tag  = 'fdownsample';
    fdownsample.name = 'Downsample factor';
    fdownsample.strtype = 'r';
    fdownsample.num = [1 1];
    fdownsample.val = {1};
    fdownsample.help = {'A number that determines mesh downsampling',...
        'e.g 5 for taking every 5th vertex'};
    
    
    mesh = cfg_branch;
    mesh.tag = 'mesh';
    mesh.name = 'Cortical mesh';
    mesh.val = {orient, fdownsample};
    
    
    return
elseif nargin < 2
    error('Two input arguments are required');
end

original = BF.data.mesh.tess_mni;

mesh = [];
mesh.canonical = original;

if S.fdownsample ~= 1
    mesh.canonical = export(gifti(reducepatch(export(gifti(mesh.canonical), 'patch'), 1/S.fdownsample)), 'spm');
end

if isfield(mesh, 'def')
    mesh.individual = spm_swarp(gifti(mesh.canonical), mesh.def);
    original        = spm_swarp(gifti(original), mesh.def);
else
    mesh.individual = mesh.canonical;
end

M = BF.data.transforms.toNative;

mesh.individual      = export(gifti(mesh.individual), 'spm');
mesh.individual.vert = spm_eeg_inv_transform_points(inv(M), mesh.individual.vert);

original = export(gifti(original), 'spm');
original.vert = spm_eeg_inv_transform_points(inv(M), original.vert);

mesh.pos = mesh.individual.vert;

switch S.orient
    case 'original'
        norm = spm_mesh_normals(export(gifti(original), 'patch'), true);
        if S.fdownsample == 1
            mesh.ori = norm;
        else
            mesh.ori = 0*mesh.pos;
            for i = 1:size(mesh.pos, 1)
                mesh.ori(i, :) = norm(all(repmat(mesh.pos(i, :), size(original.vert, 1), 1) == original.vert, 2), :);
            end
        end
    case 'downsampled'
        mesh.ori = spm_mesh_normals(export(gifti(mesh.individual), 'patch'), true);
end