namespace PSAdapter
{    
    using System;
    using System.Collections.Generic;
    using System.Text;
    using System.Text.RegularExpressions;
    using System.Threading.Tasks;
    using System.Management.Automation;
    using Microsoft.PowerShell.Cmdletization;
    using System.Collections;
    using System.Collections.ObjectModel;
    using System.Reflection;
    using System.Collections.Specialized;
    using System.Management.Automation.Runspaces;

    public class PSDotNetQueryFilter
    {
        public enum QueryFilterType
        {
            Include,
            Exclude,
            Minimum,
            Maximum
        }
        public QueryFilterType FilterType;
        public string PropertyName;
        public IEnumerable Values;
        public bool wildcardsEnabled;
    }

    public class PSDotNetQueryBuilder : QueryBuilder
    {        
        Collection<PSDotNetQueryFilter> filters;
 
        Type type;
 
        Type Type
        {
            get
            {
                return type;
            }
        }
        
        public PSDotNetQueryBuilder(Type type)
        {
            this.type = type;
            filters = new Collection<PSDotNetQueryFilter>();
        }
       
        public override void ExcludeByProperty(string propertyName, System.Collections.IEnumerable excludedPropertyValues, bool wildcardsEnabled, BehaviorOnNoMatch behaviorOnNoMatch) {
            filters.Add(
                new PSDotNetQueryFilter()
                {
                    PropertyName = propertyName,
                    Values = excludedPropertyValues,
                    wildcardsEnabled = wildcardsEnabled,
                    FilterType = PSDotNetQueryFilter.QueryFilterType.Exclude
                }
            );
        }        
 
        public override void FilterByMaxPropertyValue(string propertyName, object maxPropertyValue, BehaviorOnNoMatch behaviorOnNoMatch)
        {
            filters.Add(
                new PSDotNetQueryFilter()
                {
                    PropertyName = propertyName,
                    Values = new Object[]{ maxPropertyValue } ,
                    FilterType = PSDotNetQueryFilter.QueryFilterType.Maximum
                }
            );
        }
 
        public override void FilterByMinPropertyValue(string propertyName, object minPropertyValue, BehaviorOnNoMatch behaviorOnNoMatch)
        {
            filters.Add(
                new PSDotNetQueryFilter()
                {
                    PropertyName = propertyName,
                    Values = new Object[]{ minPropertyValue } ,
                    FilterType = PSDotNetQueryFilter.QueryFilterType.Minimum
                }
            );
        }
 
        public override void FilterByProperty(string propertyName, System.Collections.IEnumerable propertyValues, bool wildcardsEnabled, BehaviorOnNoMatch behaviorOnNoMatch )
        {
            filters.Add(
                new PSDotNetQueryFilter()
                {
                    PropertyName = propertyName,
                    Values = propertyValues,
                    wildcardsEnabled = wildcardsEnabled,
                    FilterType = PSDotNetQueryFilter.QueryFilterType.Include
                }
            );
            PSDotNetQueryFilter qf = new PSDotNetQueryFilter();
        }
 
        public bool MatchesFilters(object value, PSCmdlet cmdlet)
        {
            cmdlet.WriteVerbose(String.Format("Confirming match: {0}.  {1} Filters to process", value, filters.Count));
 
            int filterCount = 1;
            foreach (PSDotNetQueryFilter filter in filters)
            {

                cmdlet.WriteVerbose(String.Format("Processing filter #{0}.  Type: {1}", filterCount, filter.FilterType));
                filterCount++;
                PropertyInfo pi = value.GetType().GetProperty(filter.PropertyName, 
                    BindingFlags.IgnoreCase | BindingFlags.Public | BindingFlags.GetProperty | BindingFlags.GetField | BindingFlags.Instance);
                cmdlet.WriteVerbose(String.Format("Property Found {0}", pi)); 
                if (pi != null)
                {                        
                    bool excluded = false;
                    string propertyValueAsString;
                    object propValue = pi.GetValue(value, null);
                    propertyValueAsString = propValue.ToString();
                    switch (filter.FilterType)
                    {
                        case PSDotNetQueryFilter.QueryFilterType.Exclude:
                            cmdlet.WriteVerbose(String.Format("Processing Exclude Filter: Value ( {0} ) : Wildcards Enabled ( {1} ) : Possible Values ( {2} )", propValue, filter.wildcardsEnabled, filter.Values));
                            if (filter.wildcardsEnabled)
                            {
                                foreach (string exV in filter.Values)
                                {
                                    WildcardPattern wp = new WildcardPattern(exV,WildcardOptions.CultureInvariant| WildcardOptions.IgnoreCase);
                                    if (propValue != null)
                                    {
                                        propertyValueAsString = propValue.ToString();
                                        if (wp.IsMatch(propertyValueAsString))
                                        {
                                            excluded = true;
                                            break;
                                        }
                                    }
                                }
                            }
                            else
                            {
                                foreach (object exV in filter.Values)
                                {
                                    if (propValue != null && propValue == exV)
                                    {
                                        excluded = true;
                                    }
                                }

                            }
                            break;
                        case PSDotNetQueryFilter.QueryFilterType.Include:
                            cmdlet.WriteVerbose(String.Format("Processing Include Filter: Value ( {0} ) : Wildcards Enabled ( {1} ) : Possible Values ( {2} )", propValue, filter.wildcardsEnabled, filter.Values));
                            excluded = true;
                            if (filter.wildcardsEnabled)
                            {
                                foreach (string exV in filter.Values)
                                {
                                    WildcardPattern wp = new WildcardPattern(exV, WildcardOptions.CultureInvariant | WildcardOptions.IgnoreCase);
                                    if (propValue != null)
                                    {
                                        propertyValueAsString = propValue.ToString();
                                        if (wp.IsMatch(propertyValueAsString))
                                        {
                                            excluded = false;
                                            break;
                                        }
                                    }
                                }
                            }
                            else
                            {
                                foreach (object exV in filter.Values)
                                {
                                    if (propValue != null && propValue == exV)
                                    {
                                        excluded = false;
                                    }
                                }

                            }
                            break;
                        case PSDotNetQueryFilter.QueryFilterType.Maximum:
                            cmdlet.WriteVerbose(String.Format("Processing Maximum Filter: Value ( {0} ) : Max Values ( {1} )", propValue, filter.Values));
                            excluded = true;
                            foreach (object exV in filter.Values)
                            {
                                if (exV is IComparable && propValue is IComparable)
                                {
                                    IComparable orignal = propValue as IComparable;
                                    IComparable comparable = exV as IComparable;
                                    if (orignal.CompareTo(comparable) <= 0)
                                    {
                                        excluded = false;
                                    }
                                }
                            }                                

                            break;
                        case PSDotNetQueryFilter.QueryFilterType.Minimum:
                            cmdlet.WriteVerbose(String.Format("Processing Minimum Filter: Value ( {0} ) : Max Values ( {1} )", propValue, filter.Values));
                            excluded = true;
                            foreach (object exV in filter.Values)
                            {
                                if (exV is IComparable && propValue is IComparable)
                                {
                                    IComparable orignal = propValue as IComparable;
                                    IComparable comparable = exV as IComparable;
                                    if (orignal.CompareTo(comparable) >= 0)
                                    {
                                        excluded = false;
                                    }
                                }
                            }

                            break;

                    }
                    if (excluded) { return false; } 
                }

            }
            return true;
        }
    }
 
 
    public class PSDotNetAdapter : CmdletAdapter<Object>
    {        
        public override QueryBuilder GetQueryBuilder() {
            return new PSDotNetQueryBuilder(Type.GetType(this.ClassName));;
        }

        public override void BeginProcessing() {
            this.Cmdlet.WriteVerbose("Begin Processing");
        }
            
        public override void EndProcessing() {
            this.Cmdlet.WriteVerbose("End Processing");
        }

        public override void StopProcessing() {
            this.Cmdlet.WriteVerbose("Stop Processing");
            
        }

        public ScriptBlock GetMethodScriptBlock(MethodInvocationInfo methodInvocationInfo) {
            try {
                if (methodInvocationInfo.MethodName.StartsWith('{') && methodInvocationInfo.MethodName.EndsWith('}')) {
                    return ScriptBlock.Create(methodInvocationInfo.MethodName.Substring(1, methodInvocationInfo.MethodName.Length - 2));                    
                }
                return null;
            } catch (Exception ex) {
                this.Cmdlet.WriteError(new ErrorRecord(ex, "PSDotNetAdapter.InvalidScriptBlock", ErrorCategory.InvalidOperation, methodInvocationInfo));
                return null;
            }
            
        }
 
        MemberInfo ResolveMethod(Type t, string methodName, MethodInvocationInfo methodInfo, out Object[] RealParameters)
        {            
            MemberInfo realMethod = null;
            RealParameters = new Object[0];
            
            if (String.Compare(methodName, ":Constructor", true) == 0) {
                foreach (ConstructorInfo method in t.GetConstructors()) {
                    Collection<Object> realParameters = new Collection<object>();                    
                    bool anyParameterNotFound = false;
                    foreach (ParameterInfo pi in method.GetParameters())
                    {                        
                        foreach (MethodParameter mp in methodInfo.Parameters)
                        {
                            if (String.Compare(mp.Name, pi.Name, true) == 0)
                            {
                                realParameters.Add(mp.Value);
                                break;
                            } else {
                                anyParameterNotFound = true;
                                break;
                            }
                        }                        
                    }
                    if (! anyParameterNotFound) {
                        realMethod = method;
                        break;
                    }
                    RealParameters = new Object[realParameters.Count];
                    realParameters.CopyTo(RealParameters, 0);
                }
            } else {
                foreach (MethodInfo method in t.GetMethods())
                {
                    if (String.Compare(method.Name, methodName, true) == 0)
                    {
                        realMethod = method;
                        break;
                    }
                }
                if (realMethod != null)
                {
                    this.Cmdlet.WriteVerbose(String.Format("Method match found.  Method is {0}", realMethod.ToString()));
                    Collection<Object> realParameters = new Collection<object>();
 
                    ParameterInfo[] parameters =null;
                    if (realMethod is MethodInfo) {
                        parameters = ((MethodInfo)realMethod).GetParameters();
                    }
                    if (realMethod is ConstructorInfo) {
                        parameters = ((ConstructorInfo)realMethod).GetParameters();
                    } 
                    if (parameters != null) {                    
                        foreach (ParameterInfo pi in parameters)
                        {
                            foreach (MethodParameter mp in methodInfo.Parameters)
                            {
                                this.Cmdlet.WriteVerbose(String.Format("Comparing Parameter {0} to method parameter {1}", pi.Name, mp.Name));
                                if (String.Compare(mp.Name, pi.Name, true) == 0)
                                {
                                    this.Cmdlet.WriteVerbose(String.Format("Adding Parameter {0} to method parameter {1}", pi.Name, mp.Name));
                                    realParameters.Add(mp.Value);
                                    break;
                                }
                                if (mp.ParameterType != null && pi.ParameterType != null && mp.ParameterType.IsAssignableFrom(pi.ParameterType))
                                {
                                    this.Cmdlet.WriteVerbose(String.Format("Adding Parameter {0} to method parameter {1}", pi.Name, mp.Name));
                                    realParameters.Add(mp.Value);
                                    break;
                                }
                            }
                        }
                        RealParameters = new Object[realParameters.Count];
                        realParameters.CopyTo(RealParameters, 0);    
                    } else {
                        RealParameters = new Object[0];
                    }                  
                }
                else
                {
                    RealParameters = new Object[0];
                }
            }
            return realMethod;
        }
 
        public override void ProcessRecord(QueryBuilder query)
        {
            this.Cmdlet.WriteVerbose("Process Query");
            Collection<PSObject> results = GetInstances();
                         
            foreach (PSObject result in results)
            {
                this.Cmdlet.WriteVerbose(String.Format("Processing Instance {0}", result.ImmediateBaseObject));
                if ((query as PSDotNetQueryBuilder).MatchesFilters(result.ImmediateBaseObject, this.Cmdlet))
                {
                    this.Cmdlet.WriteVerbose(String.Format("Match found! {0}", result.ImmediateBaseObject));
                    this.Cmdlet.WriteObject(result, true);
                }
            }
        }
 
        public override void ProcessRecord(object objectInstance, MethodInvocationInfo methodInvocationInfo, bool passThru)
        {
            this.Cmdlet.WriteVerbose("Process instance method");
            ScriptBlock methodScriptBlock = GetMethodScriptBlock(methodInvocationInfo);
            if (methodScriptBlock != null) {
                this.Cmdlet.WriteVerbose($"Invoking method script: {methodScriptBlock}");
                foreach (var output in this.Cmdlet.SessionState.InvokeCommand.InvokeScript(methodScriptBlock.ToString(), objectInstance, methodInvocationInfo.Parameters)) {
                    this.Cmdlet.WriteObject(output, false);
                }                 
            }
            if (objectInstance == null) { return; } 
            
            Type t = objectInstance.GetType();
            
            this.Cmdlet.WriteVerbose(String.Format("Found Type {0} in Assembly {1}", this.ClassName, t.Assembly));
            Object[] realMethodParameters;
            MemberInfo realMethod = ResolveMethod(t, methodInvocationInfo.MethodName, methodInvocationInfo, out realMethodParameters);
            if (realMethod == null) {
                this.Cmdlet.WriteVerbose(String.Format("Could not find {0} on type {1}", methodInvocationInfo.MethodName, this.ClassName));
            }
            try
            {
                Object result = null;
                if (realMethod is MethodInfo) {                    
                    result = (realMethod as MethodInfo).Invoke(objectInstance, realMethodParameters);                    
                } else if (realMethod is ConstructorInfo) {
                    result = (realMethod as ConstructorInfo).Invoke(objectInstance, realMethodParameters);                   ;
                }
                if (passThru)
                {
                    if (result != null) {
                        this.Cmdlet.WriteObject(objectInstance, false);                        
                    }
                        
                }
                else
                {
                    if (result != null)
                    {
                        this.Cmdlet.WriteObject(result, true);
                    }
                }
            }
            catch (Exception ex)
            {
                if (ex.InnerException != null) {
                    this.Cmdlet.WriteError(new ErrorRecord(ex.InnerException, "PSDotNetAdapter.MethodInvocationError", ErrorCategory.InvalidOperation, objectInstance)); 
                } else {
                    this.Cmdlet.WriteError(new ErrorRecord(ex, "PSDotNetAdapter.MethodInvocationError", ErrorCategory.InvalidOperation, objectInstance)); 
                }                    
            }
            
        }
 
        public override void ProcessRecord(MethodInvocationInfo methodInvocationInfo)
        {
            this.Cmdlet.WriteVerbose("Process Static Method");
            string instanceScript = String.Empty;
            
            foreach (var kv in this.PrivateData) {
                if (kv.Key.ToLower().StartsWith(this.Cmdlet.MyInvocation.InvocationName.ToLower())) {                    
                    if (kv.Key.Substring(this.Cmdlet.MyInvocation.InvocationName.Length).ToLower() == "_instance") {
                        instanceScript = kv.Value;
                    }
                    if (kv.Key.Substring(this.Cmdlet.MyInvocation.InvocationName.Length).ToLower() == "_instanceparameter") {
                        if (this.Cmdlet.MyInvocation.BoundParameters.ContainsKey(kv.Value)) {                            
                            ProcessRecord(this.Cmdlet.MyInvocation.BoundParameters[kv.Value], methodInvocationInfo, false);
                            return;
                        }                        
                    }
                    this.Cmdlet.WriteVerbose(kv.Key + " : " + kv.Value);
                    
                }
            }

            if (! String.IsNullOrEmpty(instanceScript)) {
                this.Cmdlet.WriteVerbose("Running instance script" + instanceScript);
                Pipeline pipeline = Runspace.DefaultRunspace.CreateNestedPipeline(instanceScript, false);
                Collection<PSObject> results = pipeline.Invoke();
                foreach (PSObject result in results) {
                    ProcessRecord(result, methodInvocationInfo, false);                    
                }
                
                pipeline.Dispose();
                return;
            }

            Type t = null;
            if (LanguagePrimitives.TryConvertTo<Type>(this.ClassName, out t))
            {
                this.Cmdlet.WriteVerbose(String.Format("Found Type {0} in Assembly {1}", this.ClassName, t.Assembly));
                Object[] realMethodParameters;
                MemberInfo realMethod = ResolveMethod(t, methodInvocationInfo.MethodName, methodInvocationInfo, out realMethodParameters);
                if (realMethod == null) { return; }
                this.Cmdlet.WriteVerbose(String.Format("Method Found {0}", realMethod));
                try
                {
                    Object result = null;
                    if ((realMethod is ConstructorInfo)) {
                        result = ((ConstructorInfo)realMethod).Invoke(realMethodParameters);
                    } else if ((realMethod is MethodInfo)) {
                        result = ((MethodInfo)realMethod).Invoke(null, realMethodParameters);
                    }
                                       
                    if (result != null)
                    {                        
                        this.Cmdlet.WriteObject(result, true);                        
                    }
                }
                catch (Exception ex)
                {
                    if (ex.InnerException != null) {
                        this.Cmdlet.WriteError(new ErrorRecord(ex.InnerException, "PSDotNetAdapter.MethodInvocationError", ErrorCategory.InvalidOperation, t)); 
                    } else {
                        this.Cmdlet.WriteError(new ErrorRecord(ex, "PSDotNetAdapter.MethodInvocationError", ErrorCategory.InvalidOperation, t)); 
                    }                    
                }
            } else {
                this.Cmdlet.WriteVerbose(String.Format("Could not find type {0}", this.ClassName));
            }
 
        }

        private Collection<PSObject> GetInstances() {
            this.Cmdlet.WriteVerbose(this.Cmdlet.MyInvocation.InvocationName);
            
            string instanceScript = String.Empty;
            foreach (var kv in this.PrivateData) {
                if (kv.Key.ToLower().StartsWith(this.Cmdlet.MyInvocation.InvocationName.ToLower())) {
                    if (kv.Key.Substring(this.Cmdlet.MyInvocation.InvocationName.Length).ToLower() == "_instance") {
                        instanceScript = kv.Value;
                    }
                    if (kv.Key.Substring(this.Cmdlet.MyInvocation.InvocationName.Length).ToLower() == "_instanceparameter") {
                        if (this.Cmdlet.MyInvocation.BoundParameters.ContainsKey(kv.Value)) {
                            Collection<PSObject> instanceSet = new Collection<PSObject>();
                            instanceSet.Add(new PSObject(this.Cmdlet.MyInvocation.BoundParameters[kv.Value]));
                            return instanceSet;
                        }
                        instanceScript = kv.Value;
                    }
                    this.Cmdlet.WriteVerbose(kv.Key + " : " + kv.Value);
                    
                }
            }

            if (String.IsNullOrEmpty(instanceScript)) {
                instanceScript = @"
$pattern = '" + Regex.Escape(this.ClassName) + @"'
foreach ($var in Get-Variable -ValueOnly) {
    if ($var.pstypenames -match ) {
        $var
    }
}
";                                            
            }
            this.Cmdlet.WriteVerbose(instanceScript);
            Pipeline pipeline = Runspace.DefaultRunspace.CreateNestedPipeline(instanceScript, false);
            Collection<PSObject> results = pipeline.Invoke();
            pipeline.Dispose();
            return results;
        }
 
        public override void ProcessRecord(QueryBuilder query, MethodInvocationInfo methodInvocationInfo, bool passThru)
        {   
            this.Cmdlet.WriteVerbose("Process Query and Method");                    
            Collection<PSObject> results = GetInstances();
 
            foreach (PSObject result in results)
            {
                this.Cmdlet.WriteVerbose(String.Format("Processing Instance {0}", result.ImmediateBaseObject));
                if ((query as PSDotNetQueryBuilder).MatchesFilters(result.ImmediateBaseObject, this.Cmdlet))
                {
                    this.Cmdlet.WriteVerbose(String.Format("Match found! {0}", result.ImmediateBaseObject));
                    ProcessRecord(result.ImmediateBaseObject, methodInvocationInfo, passThru);
                }
            }
        }
    }
}
