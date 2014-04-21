#/bin/bash

function install()
{
    installdir=$( pwd )
    ruby=$(which ruby)

	plist="$HOME/Library/LaunchAgents/com.rpbyrne.winifred.plist"

    cat << EOM > "$plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC -//Apple Computer//DTD PLIST 1.0//EN http://www.apple.com/DTDs/PropertyList-1.0.dtd >
<plist version="1.0">
    <dict>
        <key>Label</key> <string>com.rpbyrne.winifred</string>
        <key>ProgramArguments</key>
            <array>
                <string>$ruby</string>
                <string>-I.</string>
                <string>server.rb</string>
            </array>
        <key>KeepAlive</key>
            <dict>
                <key>SuccessfulExit</key> <false/>
            </dict>
        <key>RunAtLoad</key> <true/>
        <key>WorkingDirectory</key> <string>$installdir</string>
        <key>StandardErrorPath</key> <string>$HOME/Library/Logs/winifred.log</string>
        <key>StandardOutPath</key> <string>$HOME/Library/Logs/winifred.log</string>
    </dict>
</plist>
EOM

    remove
    launchctl load "$plist"
    status
}

function remove()
{
    launchctl remove com.rpbyrne.winifred || { echo new launchd job ; }
}

function status()
{
    launchctl list com.rpbyrne.winifred
}



set -x -e
case "$1" in
    install|remove|status)
        $1
        ;;
    *)
        echo "Usage: $0 {install|remove|status}"
        exit 2
esac

