pod repo push STCL_REPO new-pod.podspec --allow-warnings
if [ $(echo $?) == *0* ]
then
  echo "git push was successful!"
else
  echo "me ejecuto y borro tag"
  echo "Error!" 1>&2
  exit 1
fi
