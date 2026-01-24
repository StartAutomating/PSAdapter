namespace PSAdapter
{    
    using System;
    using System.Collections.Generic;
    using System.Text;
    using System.Management.Automation;
    using Microsoft.PowerShell.Cmdletization;
    using System.Collections;
    using System.Collections.ObjectModel;
    using System.Reflection;
    using System.Collections.Specialized;
    using System.Management.Automation.Runspaces;
    using System.Text.RegularExpressions;

    public class PSEventAdapter : CmdletAdapter<Object>
    {
        public DateTime InitializationTime = DateTime.Now;

        public void OutputEvent(string eventName) {
            foreach (PSEventArgs eventArgs in this.Cmdlet.Events.ReceivedEvents) {
                if (eventArgs.SourceIdentifier == eventName) {
                    if (eventArgs.TimeGenerated < this.InitializationTime) {
                        continue;
                    }
                    this.Cmdlet.WriteObject(eventArgs);
                }
            }
        }
        
        public override void BeginProcessing() {            
            SendEvent(GetEventName("Begin"), this);
            OutputEvent(GetEventName("Begin.Response"));
        }        

        public override void StopProcessing() {
            SendEvent(GetEventName("Stop"), this);
            OutputEvent(GetEventName("Stop.Response"));
        }        
            
        public override void EndProcessing() {
            SendEvent(GetEventName("End"), this);
            OutputEvent(GetEventName("Stop.Response"));
        }
 
        public override void ProcessRecord(QueryBuilder query)
        {
            SendEvent(GetEventName("Process"), this, new object[] {query});
            OutputEvent(GetEventName("Process.Response"));
        }
 
        public override void ProcessRecord(object objectInstance, MethodInvocationInfo methodInvocationInfo, bool passThru)
        {            
            SendEvent(GetEventName("Process"), this, new object[] {objectInstance, methodInvocationInfo, passThru});
            OutputEvent(GetEventName("Process.Response"));
        }
 
        public override void ProcessRecord(MethodInvocationInfo methodInvocationInfo)
        {
            SendEvent(GetEventName("Process"), this, new object[] {methodInvocationInfo});
            OutputEvent(GetEventName("Process.Response"));
        }
         
        public override void ProcessRecord(QueryBuilder query, MethodInvocationInfo methodInvocationInfo, bool passThru)
        {         
            SendEvent(GetEventName("Process"), this, new object[] {query, methodInvocationInfo, passThru});
            OutputEvent(GetEventName("Process.Response"));
        }


        public PSEventArgs SendEvent(string sourceIdentifier, object sender = null, object[] args = null, System.Management.Automation.PSObject extraData = null) {
            if (extraData == null) {
                extraData = new PSObject(this.Cmdlet);
            }
            PSEventArgs generatedEvent = this.Cmdlet.Events.GenerateEvent(sourceIdentifier, sender, args, extraData);
            return generatedEvent;
        }

        System.Text.RegularExpressions.Regex endsWithPunctuation = new System.Text.RegularExpressions.Regex(@"\p{P}$");

        public string InvocationSourceIdentifier {
            get {
                if (string.IsNullOrEmpty(this.ClassName)) {
                    return this.Cmdlet.MyInvocation.MyCommand.Name;
                }
                else {
                    if (this.endsWithPunctuation.IsMatch(this.ClassName)) {
                        return $"{this.ClassName}{this.Cmdlet.MyInvocation.MyCommand.Name}";
                    } else {
                        return $"{this.ClassName}.{this.Cmdlet.MyInvocation.MyCommand.Name}";
                    }
                }                
            }
        }

        public string GetEventName(string eventName) {            
            string thisInvocationSourceIdentifier = this.InvocationSourceIdentifier;
            if (this.endsWithPunctuation.IsMatch(thisInvocationSourceIdentifier)) {
                return $"{thisInvocationSourceIdentifier}{eventName}";
            } else {
                return $"{thisInvocationSourceIdentifier}.{eventName}";
            }
        }
    }
}
