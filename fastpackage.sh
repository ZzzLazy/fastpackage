dirname $0
cd `dirname $0`

#############required##############
debug_app_path='/Users/mac/Library/Developer/Xcode/DerivedData/package_test-bscbewymvwsjjzcplrlvyickcecc/Build/Products/Debug-iphoneos/package_test.app'
#############if should resign############
certificate_title=""
mobileprovision_path="./embedded.mobileprovision"
############if should upload to pgyer#########
pgy_api_key=""
pgy_user_key=""



SECONDS=0
now=$(date +"%Y_%m_%d_%H_%M_%S")
workspace=`find . -name '*.xcworkspace' | head -n 1`
workspace_name=${workspace#*/}
scheme=${workspace_name%.*}
bundleShortVersion=$(/usr/libexec/PlistBuddy -c "print CFBundleShortVersionString" "./${scheme}/Info.plist")
ipa_path_dir="$(pwd)/ipas/${scheme}_${now}_v${bundleShortVersion}"
ipa_path_payload="$ipa_path_dir/Payload"
if [ ! -d $ipa_path_payload ]; then
mkdir -p $ipa_path_payload
fi
cp -R $debug_app_path $ipa_path_payload

if [[ $certificate_title != "" && $mobileprovision_path != "" ]]; then
echo ************************正在重签名****************************
cp $mobileprovision_path "$ipa_path_payload/$scheme.app/embedded.mobileprovision"
echo "重签名证书: $certificate_title" >&2
find -d $ipa_path_dir \( -name "*.app" -o -name "*.appex" -o -name "*.framework" -o -name "*.dylib" \) > directories.txt
security cms -D -i "$ipa_path_payload/$scheme.app/embedded.mobileprovision" > t_entitlements_full.plist
/usr/libexec/PlistBuddy -x -c 'Print:Entitlements' t_entitlements_full.plist > t_entitlements.plist
while IFS='' read -r line || [[ -n "$line" ]]; do
    /usr/bin/codesign --continue -f -s "$certificate_title" --entitlements "t_entitlements.plist"  "$line"
done < directories.txt
rm directories.txt
rm t_entitlements.plist
rm t_entitlements_full.plist
fi

echo **************************正在打包成ipa*********************************
cd $ipa_path_dir
zip -qry ./$scheme.ipa ./*
rm -rf $ipa_path_payload
ipa_file_path=$ipa_path_dir/$scheme.ipa
echo ipa包路径:$ipa_file_path

if [[ $pgy_user_key != "" && $pgy_api_key != "" ]]; then
echo **************************上传蒲公英************************************
curl -F file=@$ipa_file_path -F uKey=$pgy_user_key -F _api_key=$pgy_api_key https://qiniu-storage.pgyer.com/apiv1/app/upload -#
fi

echo "\n耗时: ${SECONDS}s==="
