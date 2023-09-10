import xarray
def lightter(out_grid):
    grouped_elevation = out_grid.drop("spatial_ref").groupby(out_grid.group)
    grid_mean = grouped_elevation.mean().rename({"light": "light_mean"})
    grid_min = grouped_elevation.min().rename({"light": "light_min"})
    grid_max = grouped_elevation.max().rename({"light": "light_max"})
    grid_std = grouped_elevation.std().rename({"light": "light_std"})
    # print(grid_mean, grid_min, grid_max, grid_std)
    zonal_stats = xarray.merge([grid_mean, grid_min, grid_max, grid_std], compat='override').to_dataframe()
    zonal_stats['base']=out_grid['base'].values
    zonal_stats['ctrl_dis']=out_grid['ctrl_dis'].values
    print(out_grid, zonal_stats)
    return zonal_stats