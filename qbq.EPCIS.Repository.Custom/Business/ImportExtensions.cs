namespace qbq.EPCIS.Repository.Custom.Business
{
    public static class ImportExtensions
    {
        public static string RemoveBlanks(this string str)
        {
            return str.Replace(" ", string.Empty);
        }
    }
}