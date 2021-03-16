using System.Collections.Generic;

namespace qbq.EPCIS.Repository.Custom.DataAccess
{
    /// <summary>
    /// Interface encapsulate manipulation with the data
    /// </summary>
    /// <typeparam name="T">Entity class</typeparam>
    internal interface IStorage<T>
        where T : class
    {
        /// <summary>
        /// Inserts item in the table
        /// </summary>
        /// <param name="item">Item object</param>
        void Insert(T item);

        /// <summary>
        /// Inserts the range of items to the table
        /// </summary>
        /// <param name="items">Range of item objects</param>
        void InsertRange(IEnumerable<T> items);
        
        /// <summary>
        /// Reads all the data from the table
        /// </summary>
        /// <returns>Collections of item</returns>
        IEnumerable<T> Read();
    }
}
