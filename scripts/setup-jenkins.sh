#!/bin/bash
set -e

echo "Setting up Jenkins for GitOps..."

# Wait for Jenkins to start
until curl -fsS http://localhost:8080/login > /dev/null; do
  echo "Waiting for Jenkins..."
  sleep 5
done

# Check Jenkins container exists
if ! docker ps --format '{{.Names}}' | grep -q '^jenkins$'; then
  echo "Error: Jenkins container is not running."
  exit 1
fi

# Get initial admin password
JENKINS_PASS=$(docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword)
echo "Jenkins initial password: $JENKINS_PASS"

# Create Jenkins job configuration XML
cat > jenkins-cli.xml << 'EOF'
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job">
  <description>GitOps Monitoring Pipeline</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <hudson.triggers.SCMTrigger>
          <spec>H/5 * * * *</spec>
        </hudson.triggers.SCMTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition">
    <scm class="hudson.plugins.git.GitSCM">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>file:///var/jenkins_home/workspace/tp-gitops-local</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/main</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
  </definition>
</flow-definition>
EOF

echo "Jenkins job XML created: jenkins-cli.xml"
echo "Jenkins setup complete!"
