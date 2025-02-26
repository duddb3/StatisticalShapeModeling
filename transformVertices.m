function transformed = transformVertices(vertices, params)
    % Extract affine transformation parameters
    tx = params(1); ty = params(2); tz = params(3); % Translation
    sx = params(4); sy = params(5); sz = params(6); % Scaling
    rx = params(7); ry = params(8); rz = params(9); % Rotation
    shx = params(10); shy = params(11); shz = params(12); % Shearing
    
    if sx==0
        sx = eps;
    end
    if sy==0
        sy = eps;
    end
    if sz==0
        sz = eps;
    end
    % Create translation matrix
    T_translate = makehgtform('translate', [tx, ty, tz]);
    
    % Create scaling matrix
    T_scale = makehgtform('scale', [sx, sy, sz]);
    
    % Create rotation matrices
    T_rotateX = makehgtform('xrotate', rx);
    T_rotateY = makehgtform('yrotate', ry);
    T_rotateZ = makehgtform('zrotate', rz);
    
    % Create shearing matrix
    T_shear = [1 shx shz 0; shy 1 shz 0; shx shy 1 0; 0 0 0 1];
    
    % Combine transformations
    T = T_translate * T_scale * T_rotateX * T_rotateY * T_rotateZ * T_shear;
    
    % Apply transformation
    transformed = (T(1:3, 1:3) * vertices' + T(1:3, 4))';
end
