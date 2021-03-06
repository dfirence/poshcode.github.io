using System;
using System.Windows;
using System.ComponentModel;
using System.Windows.Markup;
using System.Windows.Data;
using System.Globalization;

namespace PoshWpf
{
   public class BindingConverter : ExpressionConverter
   {
      public override bool CanConvertTo(ITypeDescriptorContext context, Type destinationType)
      {
         return (destinationType == typeof(MarkupExtension)) ? true : false;
      }
      public override object ConvertTo(ITypeDescriptorContext context, CultureInfo culture, object value, Type destinationType)
      {
         if (destinationType == typeof(MarkupExtension))
         {
            var bindingExpression = value as BindingExpression;
            if (bindingExpression == null)
               throw new Exception();
            return bindingExpression.ParentBinding;
         }

         return base.ConvertTo(context, culture, value, destinationType);
      }
   }

   public static class XamlHelper
   {
      static XamlHelper()
      {
         Register(typeof(System.Windows.Data.BindingExpression), typeof(PoshWpf.BindingConverter));
      }

      internal static void Register(Type T, Type TC)
      {
         var attr = new Attribute[] { new TypeConverterAttribute(TC) };
         TypeDescriptor.AddAttributes(T, attr);
      }

      public static string ConvertToXaml(object ui)
      {

         var outstr = new System.Text.StringBuilder();
         //this code need for right XML fomating 
         var settings = new System.Xml.XmlWriterSettings();
         settings.Indent = true;
         settings.OmitXmlDeclaration = true;

         var writer = System.Xml.XmlWriter.Create(outstr, settings);
         var dsm = new System.Windows.Markup.XamlDesignerSerializationManager(writer);
         //this string need for turning on expression saving mode 
         dsm.XamlWriterMode = System.Windows.Markup.XamlWriterMode.Expression;

         System.Windows.Markup.XamlWriter.Save(ui, dsm);
         return outstr.ToString();
      }
   }
}
