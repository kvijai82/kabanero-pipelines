#!/bin/bash
set -e

# setup environment
. $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/env.sh

# expose an extension point for running before main 'package' processing
exec_hooks $script_dir/ext/pre_package.d

pipelines_dir=$base_dir/pipelines/incubator
eventing_pipelines_dir=$base_dir/pipelines/experimental/eventing-pipelines

# directory to store assets for test or release
assets_dir=$base_dir/ci/assets
mkdir -p $assets_dir

if [[ "$OSTYPE" == "darwin"* ]]; then
    sha256cmd="shasum --algorithm 256"    # Mac OSX
else
    sha256cmd="sha256sum "  # other OSs
fi

# Generate a manifest.yaml file for each file in the tar.gz file
asset_manifest=$pipelines_dir/manifest.yaml
echo "contents:" > $asset_manifest

# for each of the assets generate a sha256 and add it to the manifest.yaml
for asset_path in $(find $pipelines_dir -type f -name '*')
do
    asset_name=${asset_path#$pipelines_dir/}
    echo "Asset name: $asset_name"
    if [ -f $asset_path ] && [ "$(basename -- $asset_path)" != "manifest.yaml" ]
    then
        sha256=$(cat $asset_path | $sha256cmd | awk '{print $1}')
        echo "- file: $asset_name" >> $asset_manifest
        echo "  sha256: $sha256" >> $asset_manifest
    fi
done

# Generate a manifest.yaml file for each file in the tar.gz file
eventing_asset_manifest=$eventing_pipelines_dir/manifest.yaml
echo "contents:" > $eventing_asset_manifest

# for each of the assets generate a sha256 and add it to the manifest.yaml
for asset_path in $(find $eventing_pipelines_dir -type f -name '*')
do
    asset_name=${asset_path#$eventing_pipelines_dir/}
    echo "Asset name: $asset_name"
    if [ -f $asset_path ] && [ "$(basename -- $asset_path)" != "manifest.yaml" ]
    then
        sha256=$(cat $asset_path | $sha256cmd | awk '{print $1}')
        echo "- file: $asset_name" >> $eventing_asset_manifest
        echo "  sha256: $sha256" >> $eventing_asset_manifest
    fi
done

# build archive of pipelines
tar -czf $assets_dir/default-kabanero-pipelines.tar.gz -C $pipelines_dir .
touch $assets_dir/default-kabanero-pipelines-tar-gz-sha256
echo $(($sha256cmd $assets_dir/default-kabanero-pipelines.tar.gz) | awk '{print $1}') >> $assets_dir/default-kabanero-pipelines-tar-gz-sha256

tar -czf $assets_dir/eventing-kabanero-pipelines.tar.gz -C $eventing_pipelines_dir .
touch $assets_dir/eventing-kabanero-pipelines-tar-gz-sha256
echo $(($sha256cmd $assets_dir/eventing-kabanero-pipelines.tar.gz) | awk '{print $1}') >> $assets_dir/eventing-kabanero-pipelines-tar-gz-sha256

echo -e "--- Created pipeline artifacts"
