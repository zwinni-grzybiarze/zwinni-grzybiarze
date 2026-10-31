using OS.Interfaces.Repositories;
using OS.Model;

namespace OS.Services.Tests;

internal sealed class FakeZadanieRepository : IZadanieRepository
{
    private readonly List<Zadanie> _items = [];
    private int _nextId = 1;

    public Zadanie? LastAdded { get; private set; }

    public Zadanie? LastUpdated { get; private set; }

    public Task<IReadOnlyList<Zadanie>> GetAllAsync(CancellationToken cancellationToken = default)
        => Task.FromResult<IReadOnlyList<Zadanie>>(_items.ToList());

    public Task<Zadanie?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
        => Task.FromResult(_items.SingleOrDefault(i => i.Id == id));

    public Task<Zadanie> AddAsync(Zadanie zadanie, CancellationToken cancellationToken = default)
    {
        zadanie.Id = _nextId++;
        LastAdded = zadanie;
        _items.Add(zadanie);
        return Task.FromResult(zadanie);
    }

    public Task<Zadanie?> UpdateAsync(Zadanie zadanie, CancellationToken cancellationToken = default)
    {
        LastUpdated = zadanie;
        var index = _items.FindIndex(i => i.Id == zadanie.Id);
        if (index < 0)
        {
            return Task.FromResult<Zadanie?>(null);
        }

        _items[index] = zadanie;
        return Task.FromResult<Zadanie?>(zadanie);
    }
}
